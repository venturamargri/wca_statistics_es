require_relative "../core/statistic"

class TwoByTwoFourMovers < Statistic
  ROUND_NAMES = {
    "0" => "Clasificación",
    "h" => "Clasificación",
    "1" => "1.ª ronda",
    "d" => "1.ª ronda",
    "2" => "2.ª ronda",
    "e" => "2.ª ronda",
    "3" => "Semifinal",
    "g" => "3.ª ronda",
    "f" => "Final",
    "c" => "Final",
    "b" => "Final B"
  }.freeze

  module Solver
    NORMAL_TO_FACE = {
      [0, 1, 0] => "U",
      [1, 0, 0] => "R",
      [0, 0, 1] => "F",
      [0, -1, 0] => "D",
      [-1, 0, 0] => "L",
      [0, 0, -1] => "B"
    }.freeze
    FACE_TO_NORMAL = NORMAL_TO_FACE.invert.freeze

    SLOTS = begin
      arr = []
      [-1, 1].each do |x|
        [-1, 1].each do |y|
          [-1, 1].each do |z|
            arr << [[x, y, z], [x, 0, 0]]
            arr << [[x, y, z], [0, y, 0]]
            arr << [[x, y, z], [0, 0, z]]
          end
        end
      end
      arr.freeze
    end

    SLOT_INDEX = SLOTS.each_with_index.to_h.freeze
    SOLVED_STATE = SLOTS.map { |_, n| NORMAL_TO_FACE[n] }.join.freeze

    DBL_D = SLOT_INDEX[[[-1, -1, -1], [0, -1, 0]]]
    DBL_B = SLOT_INDEX[[[-1, -1, -1], [0, 0, -1]]]
    DBL_L = SLOT_INDEX[[[-1, -1, -1], [-1, 0, 0]]]

    D_ORD = "D".ord
    B_ORD = "B".ord
    L_ORD = "L".ord

    def self.build_perm(filter_fn, rot_fn)
      perm = Array.new(24)
      SLOTS.each_with_index do |(pos, norm), src_idx|
        if filter_fn.call(pos)
          dst_idx = SLOT_INDEX[[rot_fn.call(*pos), rot_fn.call(*norm)]]
        else
          dst_idx = src_idx
        end
        perm[dst_idx] = src_idx
      end
      perm.freeze
    end

    def self.compose_perm(first_p, second_p)
      second_p.map { |i| first_p[i] }.freeze
    end

    def self.apply_perm(state, perm)
      out = String.new(capacity: 24)
      perm.each { |i| out << state.getbyte(i) }
      out
    end

    def self.invert_move(move)
      face = move[0]
      case move[1..-1]
      when "" then "#{face}'"
      when "'" then face
      when "2" then "#{face}2"
      else move
      end
    end

    MOVES = begin
      base = {
        "R" => build_perm(->(p) { p[0] == 1 }, ->(x, y, z) { [x, z, -y] }),
        "L" => build_perm(->(p) { p[0] == -1 }, ->(x, y, z) { [x, -z, y] }),
        "U" => build_perm(->(p) { p[1] == 1 }, ->(x, y, z) { [-z, y, x] }),
        "D" => build_perm(->(p) { p[1] == -1 }, ->(x, y, z) { [z, y, -x] }),
        "F" => build_perm(->(p) { p[2] == 1 }, ->(x, y, z) { [y, -x, z] }),
        "B" => build_perm(->(p) { p[2] == -1 }, ->(x, y, z) { [-y, x, z] })
      }
      all = {}
      base.each do |face, p1|
        p2 = compose_perm(p1, p1)
        p3 = compose_perm(p2, p1)
        all[face] = p1
        all["#{face}2"] = p2
        all["#{face}'"] = p3
      end
      all.freeze
    end

    ROTATIONS = begin
      all_true = ->(_) { true }
      steps = [
        [
          build_perm(all_true, ->(x, y, z) { [x, z, -y] }),
          NORMAL_TO_FACE.values.to_h { |f| x, y, z = FACE_TO_NORMAL[f]; [f, NORMAL_TO_FACE[[x, -z, y]]] }
        ],
        [
          build_perm(all_true, ->(x, y, z) { [-z, y, x] }),
          NORMAL_TO_FACE.values.to_h { |f| x, y, z = FACE_TO_NORMAL[f]; [f, NORMAL_TO_FACE[[z, y, -x]]] }
        ],
        [
          build_perm(all_true, ->(x, y, z) { [y, -x, z] }),
          NORMAL_TO_FACE.values.to_h { |f| x, y, z = FACE_TO_NORMAL[f]; [f, NORMAL_TO_FACE[[-y, x, z]]] }
        ]
      ]

      id_perm = (0...24).to_a.freeze
      id_map = NORMAL_TO_FACE.values.to_h { |f| [f, f] }.freeze
      seen = { SOLVED_STATE => true }
      queue = [{ perm: id_perm, inv_map: id_map }]
      idx = 0

      while idx < queue.length
        cur = queue[idx]
        idx += 1
        steps.each do |step_perm, step_inv_map|
          next_perm = compose_perm(cur[:perm], step_perm)
          key = apply_perm(SOLVED_STATE, next_perm)
          next if seen[key]

          seen[key] = true
          next_inv = step_inv_map.transform_values { |f| cur[:inv_map][f] }.freeze
          queue << { perm: next_perm, inv_map: next_inv }
        end
      end
      queue.freeze
    end

    def self.four_movers
      @four_movers ||= begin
        ruf_moves = %w[R R' R2 U U' U2 F F' F2]
        visited = { SOLVED_STATE => [0, []] }
        queue = [[SOLVED_STATE, 0, []]]
        idx = 0

        while idx < queue.length
          state, depth, sol = queue[idx]
          idx += 1
          next if depth >= 4

          ruf_moves.each do |mv|
            next_state = apply_perm(state, MOVES[mv])
            next if visited.key?(next_state)

            next_sol = [invert_move(mv)] + sol
            visited[next_state] = [depth + 1, next_sol]
            queue << [next_state, depth + 1, next_sol]
          end
        end

        visited.select { |_, (d, _)| d == 4 }.transform_values(&:last).freeze
      end
    end

    def self.solve_if_four_mover(scramble_str)
      tokens = scramble_str.to_s.strip.split(/\s+/)
      return nil if tokens.empty?

      state = SOLVED_STATE
      tokens.each do |tok|
        perm = MOVES[tok]
        return nil unless perm

        state = apply_perm(state, perm)
      end

      rot = ROTATIONS.find do |r|
        p = r[:perm]
        state.getbyte(p[DBL_D]) == D_ORD &&
          state.getbyte(p[DBL_B]) == B_ORD &&
          state.getbyte(p[DBL_L]) == L_ORD
      end
      return nil unless rot

      norm_state = apply_perm(state, rot[:perm])
      sol_ruf = four_movers[norm_state]
      return nil unless sol_ruf

      sol_ruf.map { |m| "#{rot[:inv_map][m[0]]}#{m[1..-1]}" }.join(" ")
    end
  end

  def initialize
    @title = "Todas las 4-movers de 2x2x2"
    @category = :results
    @note = "Mezclas oficiales de 2x2x2 (incluyendo mezclas extra) utilizadas en competiciones celebradas en España cuya solución óptima en métrica HTM es exactamente de 4 movimientos."
    @table_header = {
      "Competición" => :left,
      "Ronda" => :left,
      "Grupo" => :center,
      "N.º" => :center,
      "Mezcla" => :left,
      "Solución óptima" => :left
    }
  end

  def query
    <<-SQL
      SELECT
        'scramble' AS row_type,
        s.competition_id,
        s.round_type_id,
        rt.cell_name AS round_name,
        rt.rank AS round_rank,
        s.group_id,
        s.is_extra,
        s.scramble_num,
        s.scramble,
        c.start_date,
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, '/results/all#e222_', s.round_type_id, ')') AS comp_link,
        NULL AS person_id,
        NULL AS person_name,
        NULL AS person_link
      FROM scrambles s
      JOIN competitions c ON c.id = s.competition_id
      JOIN round_types rt ON rt.id = s.round_type_id
      WHERE c.country_id = 'Spain'
        AND s.event_id = '222'

      UNION ALL

      SELECT
        'result' AS row_type,
        r.competition_id,
        r.round_type_id,
        NULL AS round_name,
        NULL AS round_rank,
        NULL AS group_id,
        NULL AS is_extra,
        NULL AS scramble_num,
        NULL AS scramble,
        NULL AS start_date,
        NULL AS comp_link,
        r.person_id,
        p.name AS person_name,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link
      FROM results r
      JOIN competitions c ON c.id = r.competition_id
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1
      WHERE c.country_id = 'Spain'
        AND r.event_id = '222'
    SQL
  end

  def transform(query_results)
    four_mover_rows = []
    round_four_movers = Hash.new { |h, k| h[k] = [] }
    results_by_round = Hash.new { |h, k| h[k] = [] }

    query_results.each do |r|
      if r["row_type"] == "scramble"
        scramble = r["scramble"].to_s.strip.gsub(/\s+/, " ")
        solution = Solver.solve_if_four_mover(scramble)
        next unless solution

        is_extra = (r["is_extra"] == true || r["is_extra"] == 1 || r["is_extra"].to_s == "1")
        date_int = r["start_date"].to_s.delete("-").to_i
        round_label = ROUND_NAMES[r["round_type_id"]] || r["round_name"]
        num_label = is_extra ? "Extra #{r['scramble_num']}" : r["scramble_num"].to_s

        entry = {
          comp_id: r["competition_id"],
          round_type_id: r["round_type_id"],
          round_rank: r["round_rank"].to_i,
          group_id: r["group_id"].to_s,
          is_extra_int: is_extra ? 1 : 0,
          scramble_num: r["scramble_num"].to_i,
          date_int: date_int,
          comp_link: r["comp_link"],
          round_label: round_label,
          num_label: num_label,
          scramble: scramble,
          solution: solution
        }

        four_mover_rows << entry
        round_four_movers[[entry[:comp_id], entry[:round_type_id]]] << entry
      else
        results_by_round[[r["competition_id"], r["round_type_id"]]] << {
          person_id: r["person_id"],
          person_name: r["person_name"],
          person_link: r["person_link"]
        }
      end
    end

    four_mover_rows.sort_by! do |e|
      [-e[:date_int], e[:comp_id], e[:round_rank], e[:group_id], e[:is_extra_int], e[:scramble_num]]
    end

    # Calcular tabla de 4-movers potencialmente ejecutadas
    person_hits = Hash.new do |h, k|
      h[k] = { name: nil, link: nil, count: 0, comps: {} }
    end

    round_four_movers.each do |round_key, entries|
      participants = results_by_round[round_key]
      next if participants.empty?

      seen_in_round = {}
      participants.each do |p|
        pid = p[:person_id]
        next if seen_in_round[pid]
        seen_in_round[pid] = true

        rec = person_hits[pid]
        rec[:name] = p[:person_name]
        rec[:link] = p[:person_link]
        rec[:count] += entries.size

        first_entry = entries.first
        rec[:comps][first_entry[:comp_id]] ||= {
          date_int: first_entry[:date_int],
          comp_id: first_entry[:comp_id],
          comp_link: first_entry[:comp_link]
        }
      end
    end

    @potential_rows = person_hits.values
      .select { |rec| rec[:comps].size >= 2 }
      .sort_by { |rec| [-rec[:count], -rec[:comps].size, rec[:name]] }
      .map do |rec|
        comps_str = rec[:comps].values
          .sort_by { |c| [-c[:date_int], c[:comp_id]] }
          .map { |c| c[:comp_link] }
          .join(", ")
        [rec[:link], rec[:count], comps_str]
      end

    four_mover_rows.map do |e|
      [
        e[:comp_link],
        e[:round_label],
        e[:group_id],
        e[:num_label],
        "`#{e[:scramble]}`",
        "`#{e[:solution]}`"
      ]
    end
  end

  def markdown
    md = super
    return md if @potential_rows.nil? || @potential_rows.empty?

    extra = [
      "",
      "## 4-movers potencialmente ejecutadas",
      "",
      "Personas que compitieron en la ronda de 2x2x2 correspondiente en 2 o más competiciones donde salió una 4-mover (no se puede garantizar que la ejecutaran si la ronda tuvo varios grupos o fue una mezcla extra).",
      "",
      "| Persona | 4-movers | Competiciones |",
      "| :--- | ---: | :--- |"
    ]

    @potential_rows.each do |person_link, count, comps_str|
      extra << "| #{person_link} | #{count} | #{comps_str} |"
    end

    md.rstrip + "\n" + extra.join("\n") + "\n"
  end
end

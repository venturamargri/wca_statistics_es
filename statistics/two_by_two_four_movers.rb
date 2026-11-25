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
        s.competition_id,
        s.round_type_id,
        rt.cell_name AS round_name,
        rt.rank AS round_rank,
        s.group_id,
        s.is_extra,
        s.scramble_num,
        s.scramble,
        c.start_date,
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, '/results/all#e222_', s.round_type_id, ')') AS comp_link
      FROM scrambles s
      JOIN competitions c ON c.id = s.competition_id
      JOIN round_types rt ON rt.id = s.round_type_id
      WHERE c.country_id = 'Spain'
        AND s.event_id = '222'
      ORDER BY c.start_date DESC, c.id ASC, rt.rank ASC, s.group_id ASC, s.is_extra ASC, s.scramble_num ASC
    SQL
  end

  def transform(query_results)
    query_results.filter_map do |r|
      scramble = r["scramble"].to_s.strip.gsub(/\s+/, " ")
      solution = Solver.solve_if_four_mover(scramble)
      next unless solution

      round_label = ROUND_NAMES[r["round_type_id"]] || r["round_name"]
      is_extra = (r["is_extra"] == true || r["is_extra"] == 1 || r["is_extra"].to_s == "1")
      num_label = is_extra ? "Extra #{r['scramble_num']}" : r["scramble_num"].to_s

      [
        r["comp_link"],
        round_label,
        r["group_id"],
        num_label,
        "`#{scramble}`",
        "`#{solution}`"
      ]
    end
  end
end

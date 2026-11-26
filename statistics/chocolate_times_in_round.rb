require_relative "../core/statistic"
require_relative "../core/events"
require_relative "../core/solve_time"

class ChocolateTimesInRound < Statistic
  def initialize
    @title = "Tiempos chocolate (.00)"
    @category = :results
    @note = "Rondas y competiciones oficiales de competidores españoles con más tiempos exactos acabados en .00 (se excluyen FMC, Multi-Blind y tiempos de 10 minutos o más, ya que se truncan a los segundos)."
    @table_header = {
      "Tiempos .00" => :center,
      "Persona" => :left,
      "Categoría" => :left,
      "Tiempos de la ronda" => :left,
      "Competición" => :left
    }
  end

  def query
    <<-SQL
      WITH spain_chocs AS (
        SELECT
          r.id AS result_id,
          r.person_id,
          r.competition_id
        FROM results r
        JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
        JOIN result_attempts ra ON ra.result_id = r.id
        WHERE r.event_id NOT IN ('333fm', '333mbf', '333mbo')
          AND ra.value > 0
          AND ra.value < 60000
          AND (ra.value % 100) = 0
      ),
      choc_rounds AS (
        SELECT
          result_id,
          COUNT(*) AS choc_count
        FROM spain_chocs
        GROUP BY result_id
        HAVING COUNT(*) >= 2
      ),
      choc_comps AS (
        SELECT
          person_id,
          competition_id,
          COUNT(*) AS choc_count
        FROM spain_chocs
        GROUP BY person_id, competition_id
        HAVING COUNT(*) >= 2
      )
      SELECT
        'round' AS row_type,
        cr.result_id,
        cr.choc_count,
        r.event_id,
        p.name AS person_name,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, '/results/all#e', r.event_id, '_', r.round_type_id, ')') AS comp_link,
        c.start_date,
        ra.attempt_number,
        ra.value
      FROM choc_rounds cr
      JOIN results r ON r.id = cr.result_id
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1
      JOIN competitions c ON c.id = r.competition_id
      JOIN result_attempts ra ON ra.result_id = r.id
      WHERE ra.value != 0

      UNION ALL

      SELECT
        'comp' AS row_type,
        NULL AS result_id,
        cc.choc_count,
        NULL AS event_id,
        p.name AS person_name,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, ')') AS comp_link,
        c.start_date,
        NULL AS attempt_number,
        NULL AS value
      FROM choc_comps cc
      JOIN persons p ON p.wca_id = cc.person_id AND p.sub_id = 1
      JOIN competitions c ON c.id = cc.competition_id
    SQL
  end

  def transform(query_results)
    round_rows = []
    comp_rows = []

    query_results.each do |r|
      if r["row_type"] == "comp"
        comp_rows << r
      else
        round_rows << r
      end
    end

    @comp_rows = comp_rows
      .map do |r|
        date_ord = r["start_date"].respond_to?(:jd) ? r["start_date"].jd : r["start_date"].to_s.delete("-").to_i
        {
          choc_count: r["choc_count"].to_i,
          date_ord: date_ord,
          person_name: r["person_name"].to_s,
          person_link: r["person_link"],
          comp_link: r["comp_link"]
        }
      end
      .sort_by { |x| [-x[:choc_count], -x[:date_ord], x[:person_name], x[:comp_link]] }
      .first(50)
      .map { |x| [x[:person_link], x[:comp_link], x[:choc_count]] }

    rounds = round_rows.group_by { |r| r["result_id"] }.values.map do |attempts|
      first = attempts.first
      event_id = first["event_id"]
      sorted_attempts = attempts.sort_by { |a| a["attempt_number"].to_i }

      formatted = sorted_attempts.map do |a|
        val = a["value"].to_i
        if val == -1
          "DNF"
        elsif val == -2
          "DNS"
        else
          str = SolveTime.new(event_id, :single, val).clock_format
          (val > 0 && val < 60_000 && (val % 100) == 0) ? "**#{str}**" : str
        end
      end.join(", ")

      date_ord = first["start_date"].respond_to?(:jd) ? first["start_date"].jd : first["start_date"].to_s.delete("-").to_i

      {
        choc_count: first["choc_count"].to_i,
        total_attempts: sorted_attempts.size,
        date_ord: date_ord,
        person_link: first["person_link"],
        event_name: Events::ALL[event_id] || event_id,
        formatted: formatted,
        comp_link: first["comp_link"]
      }
    end

    three_plus = rounds.select { |x| x[:choc_count] >= 3 }
    selected = three_plus.size >= 10 ? three_plus : rounds

    selected
      .sort_by { |x| [-x[:choc_count], x[:total_attempts], -x[:date_ord], x[:person_link]] }
      .first(50)
      .map { |x| ["#{x[:choc_count]} / #{x[:total_attempts]}", x[:person_link], x[:event_name], x[:formatted], x[:comp_link]] }
  end

  def markdown
    md = super
    return md if @comp_rows.nil? || @comp_rows.empty?

    extra = [
      "",
      "## Más tiempos chocolate (.00) en una competición",
      "",
      "| Persona | Competición | Chocolates |",
      "| :--- | :--- | ---: |"
    ]

    @comp_rows.each do |person_link, comp_link, count|
      extra << "| #{person_link} | #{comp_link} | #{count} |"
    end

    md.rstrip + "\n" + extra.join("\n") + "\n"
  end
end

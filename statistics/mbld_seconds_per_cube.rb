require_relative "../core/statistic"
require_relative "../core/solve_time"

class MbldSecondsPerCube < Statistic
  def initialize
    @title = "Mejor ritmo en 3x3x3 Multi-Blind"
    @category = :results
    @note = "Menor tiempo medio por cubo intentado en intentos oficiales válidos de 3x3x3 Multi-Blind con al menos 5 cubos intentados (los DNF no registran tiempo ni cubos en la base de datos). Se muestra el mejor registro de cada persona."
    @table_header = {
      "Seg / cubo" => :right,
      "Persona" => :left,
      "Resultado" => :right,
      "Intentados" => :right,
      "Competición" => :left
    }
  end

  def query
    <<-SQL
      SELECT
        r.person_id,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        ra.value,
        c.start_date,
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, '/results/all#e', r.event_id, '_', r.round_type_id, ')') AS comp_link
      FROM results r
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      JOIN result_attempts ra ON ra.result_id = r.id
      JOIN competitions c ON c.id = r.competition_id
      WHERE r.event_id = '333mbf'
        AND ra.value > 0
        AND ra.value < 1000000000
    SQL
  end

  def transform(query_results)
    candidates = query_results.filter_map do |r|
      val = r["value"].to_i
      diff = 99 - (val / 10_000_000)
      time_sec = (val / 100) % 100_000
      missed = val % 100
      solved = diff + missed
      attempted = solved + missed

      next if time_sec <= 0 || time_sec >= 99_999 || attempted < 5

      {
        person_id: r["person_id"],
        sec_per_cube: time_sec.to_f / attempted,
        attempted: attempted,
        val: val,
        start_date: r["start_date"].to_s,
        person_link: r["person_link"],
        comp_link: r["comp_link"]
      }
    end

    candidates
      .group_by { |x| x[:person_id] }
      .values
      .map { |rows| rows.min_by { |x| [x[:sec_per_cube], -x[:attempted], x[:start_date]] } }
      .sort_by { |x| [x[:sec_per_cube], -x[:attempted], x[:person_link]] }
      .first(50)
      .map do |x|
        [
          format("%.2f s", x[:sec_per_cube]),
          x[:person_link],
          SolveTime.new("333mbf", :single, x[:val]).clock_format,
          x[:attempted],
          x[:comp_link]
        ]
      end
  end
end

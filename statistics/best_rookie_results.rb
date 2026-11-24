require_relative "../core/grouped_statistic"
require_relative "../core/events"
require_relative "../core/solve_time"

class BestRookieResults < GroupedStatistic
  def initialize
    @title = "Mejores marcas de rookies"
    @category = :results
    @note = "Mejores singles y averages logrados por competidores españoles con menos de 366 días transcurridos desde su primera competición oficial (debut absoluto en la WCA). Se muestra la mejor marca rookie de cada persona."
    @table_header = {
      "Marca" => :right,
      "Persona" => :left,
      "Días desde debut" => :right,
      "Competición" => :left
    }
  end

  def query
    <<-SQL
      WITH spanish_persons AS (
        SELECT wca_id, name
        FROM persons
        WHERE sub_id = 1 AND country_id = 'Spain'
      ),
      debuts AS (
        SELECT r.person_id, MIN(c.start_date) AS first_date
        FROM results r
        JOIN spanish_persons sp ON sp.wca_id = r.person_id
        JOIN competitions c ON c.id = r.competition_id
        GROUP BY r.person_id
      )
      SELECT
        r.event_id,
        r.person_id,
        CONCAT('[', sp.name, '](https://www.worldcubeassociation.org/persons/', sp.wca_id, ')') AS person_link,
        r.best,
        r.average,
        DATEDIFF(c.start_date, d.first_date) AS days_since_debut,
        c.start_date,
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, '/results/all#e', r.event_id, '_', r.round_type_id, ')') AS comp_link
      FROM results r
      JOIN spanish_persons sp ON sp.wca_id = r.person_id
      JOIN debuts d ON d.person_id = r.person_id
      JOIN competitions c ON c.id = r.competition_id
      WHERE DATEDIFF(c.start_date, d.first_date) < 366
        AND r.best > 0
    SQL
  end

  def transform(query_results)
    by_event = query_results.group_by { |r| r["event_id"] }
    groups = []

    Events::ALL.each do |event_id, event_name|
      event_rows = by_event[event_id] || []

      [[:single, "best", "Single"], [:average, "average", "Average"]].each do |type, col, label|
        next if event_id == "333mbf" && type == :average

        rows = event_rows
          .select { |r| r[col] > 0 }
          .group_by { |r| r["person_id"] }
          .values
          .map { |pr| pr.min_by { |r| [r[col], r["days_since_debut"], r["start_date"]] } }
          .sort_by { |r| [r[col], r["days_since_debut"], r["person_link"]] }
          .first(10)
          .map do |r|
            [
              SolveTime.new(event_id, type, r[col]).clock_format,
              r["person_link"],
              r["days_since_debut"],
              r["comp_link"]
            ]
          end

        groups << ["#{event_name} - #{label}", rows] unless rows.empty?
      end
    end

    groups
  end
end

require_relative "../core/statistic"
require_relative "../core/events"
require_relative "../core/spanish_format"

class TimeToPodiumInAllEvents < Statistic
  def initialize
    @title = "Tiempo en hacer podio en todas las categorías"
    @category = :podiums
    @note = "Días transcurridos desde la primera competición oficial hasta conseguir al menos un podio en las 17 categorías oficiales actuales."
    @table_header = {
      "Días" => :right,
      "Persona" => :left,
      "Debut" => :left,
      "Completado" => :left,
      "Última categoría" => :left
    }
  end

  def query
    event_list = Events::ALL.keys.map { |e| "'#{e}'" }.join(", ")
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
      ),
      first_podiums AS (
        SELECT
          r.person_id,
          r.event_id,
          MIN(c.start_date) AS first_podium_date
        FROM results r
        JOIN spanish_persons sp ON sp.wca_id = r.person_id
        JOIN round_types rt ON rt.id = r.round_type_id AND rt.final = 1
        JOIN competitions c ON c.id = r.competition_id
        WHERE r.pos IN (1, 2, 3)
          AND r.best > 0
          AND r.event_id IN (#{event_list})
        GROUP BY r.person_id, r.event_id
      )
      SELECT
        fp.person_id,
        CONCAT('[', sp.name, '](https://www.worldcubeassociation.org/persons/', sp.wca_id, ')') AS person_link,
        fp.event_id,
        d.first_date,
        fp.first_podium_date,
        DATEDIFF(fp.first_podium_date, d.first_date) AS days_from_debut
      FROM first_podiums fp
      JOIN spanish_persons sp ON sp.wca_id = fp.person_id
      JOIN debuts d ON d.person_id = fp.person_id
    SQL
  end

  def transform(query_results)
    total_events = Events::ALL.size

    query_results
      .group_by { |r| r["person_id"] }
      .values
      .select { |rows| rows.size == total_events }
      .map do |rows|
        max_days = rows.map { |r| r["days_from_debut"] }.max
        last_rows = rows.select { |r| r["days_from_debut"] == max_days }
        last_events = last_rows.map { |r| Events::ALL[r["event_id"]] }.join(", ")
        first_row = rows.first
        completion_date = last_rows.first["first_podium_date"]
        {
          days: max_days,
          person_link: first_row["person_link"],
          debut: SpanishFormat.short_date(first_row["first_date"]),
          completed: SpanishFormat.short_date(completion_date),
          last_events: last_events
        }
      end
      .sort_by { |x| [x[:days], x[:person_link]] }
      .map { |x| [x[:days], x[:person_link], x[:debut], x[:completed], x[:last_events]] }
  end
end

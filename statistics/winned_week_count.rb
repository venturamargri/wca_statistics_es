require_relative "../core/grouped_statistic"

class WinnedWeekCount < GroupedStatistic
  def initialize
    @title = "Más semanas ganadas"
    @category = :podiums
    @note = "Número de semanas (de lunes a domingo) en las que el competidor logró el mejor single de todos los competidores españoles en esa categoría."
    @table_header = { "Persona" => :left, "Semanas ganadas" => :right }
  end

  def query
    <<-SQL
      SELECT
        event_id,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
        winned_weeks
      FROM (
        SELECT wb.event_id, r.person_id, COUNT(DISTINCT wb.week_start) AS winned_weeks
        FROM (
          SELECT
            results.event_id,
            MIN(results.best) AS week_best,
            DATE_ADD(competition.start_date, INTERVAL(-WEEKDAY(competition.start_date)) DAY) AS week_start
          FROM results
          JOIN competitions competition ON competition.id = results.competition_id
          JOIN persons p ON p.wca_id = results.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
          WHERE results.best > 0
          GROUP BY results.event_id, week_start
        ) wb
        JOIN results r ON r.event_id = wb.event_id AND r.best = wb.week_best
        JOIN persons p2 ON p2.wca_id = r.person_id AND p2.sub_id = 1 AND p2.country_id = 'Spain'
        JOIN competitions c ON c.id = r.competition_id
          AND DATE_ADD(c.start_date, INTERVAL(-WEEKDAY(c.start_date)) DAY) = wb.week_start
        GROUP BY wb.event_id, r.person_id
      ) AS winned_weeks_by_person
      JOIN persons person ON person.wca_id = person_id AND sub_id = 1 AND person.country_id = 'Spain'
    SQL
  end

  def transform(query_results)
    Events::ALL.map do |event_id, event_name|
      results = query_results
        .select { |result| result["event_id"] == event_id }
        .sort_by! { |result| [-result["winned_weeks"], result["person_link"]] }
        .first(20)
        .map! { |result| [result["person_link"], result["winned_weeks"]] }
      [event_name, results]
    end
  end
end

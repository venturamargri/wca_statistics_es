require_relative "../core/statistic"

class AverageNewPeopleMetPerCompetition < Statistic
  MIN_COMPETITIONS = 20

  def initialize
    @title = "Mayor media de personas nuevas conocidas por competición"
    @category = :competing
    @note = "Divide el total de competidores únicos con los que se ha coincidido a lo largo de la carrera entre el número de competiciones disputadas. Mínimo #{MIN_COMPETITIONS} competiciones."
    @table_header = { "Media nuevas personas" => :right, "Personas únicas" => :right, "Competiciones" => :right, "Persona" => :left }
  end

  def query
    <<-SQL
      SELECT
        COUNT(DISTINCT co_competitor.person_id) / COUNT(DISTINCT attendance.competition_id) average_new_people,
        COUNT(DISTINCT co_competitor.person_id) unique_people,
        COUNT(DISTINCT attendance.competition_id) competitions,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link
      FROM (
        SELECT DISTINCT r.person_id, r.competition_id
        FROM results r
        JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      ) AS attendance
      LEFT JOIN results co_competitor
        ON co_competitor.competition_id = attendance.competition_id
        AND co_competitor.person_id != attendance.person_id
      JOIN persons person ON person.wca_id = attendance.person_id AND person.sub_id = 1
      GROUP BY attendance.person_id, person_link
      HAVING competitions >= #{MIN_COMPETITIONS}
      ORDER BY average_new_people DESC, unique_people DESC, person_link
      LIMIT 100
    SQL
  end

  def transform(query_results)
    query_results.map do |result|
      [
        format("%.2f", result["average_new_people"]),
        result["unique_people"],
        result["competitions"],
        result["person_link"]
      ]
    end
  end
end

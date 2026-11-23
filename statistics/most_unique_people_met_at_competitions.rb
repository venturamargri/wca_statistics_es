require_relative "../core/statistic"

class MostUniquePeopleMetAtCompetitions < Statistic
  def initialize
    @title = "Más personas distintas conocidas en competiciones"
    @category = :competing
    @note = "Dos personas cuentan como conocidas si ambas registraron al menos un resultado en la misma competición."
    @table_header = { "Personas conocidas" => :right, "Competiciones" => :right, "Persona" => :left }
  end

  def query
    <<-SQL
      SELECT
        COUNT(DISTINCT co_competitor.person_id) people_met,
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
      ORDER BY people_met DESC, competitions DESC, person_link
      LIMIT 100
    SQL
  end
end

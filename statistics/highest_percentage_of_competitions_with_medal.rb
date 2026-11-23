require_relative "../core/statistic"

class HighestPercentageOfCompetitionsWithMedal < Statistic
  def initialize
    @title = "Mayor porcentaje de competiciones con al menos una medalla"
    @category = :podiums
    @note = "Una medalla equivale a quedar entre los 3 primeros en una final. Solo competidores españoles con al menos 10 competiciones."
    @table_header = { "Porcentaje" => :right, "Con medalla" => :right, "Competiciones" => :right, "Persona" => :left }
  end

  def query
    <<-SQL
      SELECT
        CONCAT(FORMAT(100 * competitions_with_medal / competitions, 1), '%') share,
        competitions_with_medal,
        competitions,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link
      FROM (
        SELECT
          results.person_id,
          COUNT(DISTINCT results.competition_id) competitions,
          COUNT(DISTINCT CASE WHEN results.pos IN (1, 2, 3) AND results.best > 0 AND results.round_type_id IN ('c', 'f') THEN results.competition_id END) competitions_with_medal
        FROM results
        JOIN persons person ON person.wca_id = results.person_id AND person.sub_id = 1 AND person.country_id = 'Spain'
        GROUP BY results.person_id
        HAVING competitions >= 10
      ) AS stats
      JOIN persons person ON person.wca_id = stats.person_id AND person.sub_id = 1
      ORDER BY competitions_with_medal / competitions DESC, competitions DESC, person.name
      LIMIT 100
    SQL
  end
end

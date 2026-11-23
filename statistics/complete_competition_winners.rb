require_relative "../core/statistic"

class CompleteCompetitionWinners < Statistic
  def initialize
    @title = "Ganadores de todas las categorías de una competición"
    @category = :podiums
    @note = "Una victoria completa consiste en ganar el primer puesto en todas las categorías disputadas en esa competición."
    @table_header = { "Categorías" => :right, "Persona" => :left, "País" => :left, "Competición" => :left }
  end

  def query
    <<-SQL
      SELECT
        events_count,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
        country.name,
        CONCAT('[', competition.cell_name, '](https://www.worldcubeassociation.org/competitions/', competition.id, ')') competition_link
      FROM (
        SELECT
          competition_id,
          GROUP_CONCAT(DISTINCT person_id) personId,
          COUNT(DISTINCT event_id) events_count
        FROM results
        WHERE round_type_id IN ('c', 'f') AND pos = 1 AND best > 0
        GROUP BY competition_id
        HAVING COUNT(DISTINCT person_id) = 1
      ) AS competitions_with_complete_winners
      JOIN persons person ON person.wca_id = personId AND sub_id = 1
      JOIN competitions competition ON competition.id = competition_id
      JOIN countries country ON country.id = person.country_id
      WHERE person.country_id = 'Spain'
      ORDER BY events_count DESC, person.name
    SQL
  end  
end

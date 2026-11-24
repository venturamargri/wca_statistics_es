require_relative "../core/statistic"

class BiggestCompetitionsInSpain < Statistic
  def initialize
    @title = "Mayores competiciones"
    @category = :competitions
    @note = "Se cuenta a todo competidor con al menos un resultado, independientemente de su nacionalidad."
    @table_header = { "Competidores" => :right, "Competición" => :left }
  end

  def query
    <<-SQL
      SELECT
        competitors_count,
        CONCAT('[', competition.cell_name, '](https://www.worldcubeassociation.org/competitions/', competition.id, ')') competition
      FROM (
        SELECT
          COUNT(DISTINCT person_id) competitors_count,
          competition_id
        FROM results
        GROUP BY competition_id
      ) AS competitors_count_by_competition
      JOIN competitions competition ON competition.id = competition_id AND competition.country_id = 'Spain'
      ORDER BY competitors_count DESC, competition.start_date
      LIMIT 50
    SQL
  end
end

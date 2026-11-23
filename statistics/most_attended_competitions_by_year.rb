require_relative "../core/grouped_statistic"

class MostAttendedCompetitionsByYear < GroupedStatistic
  def initialize
    @title = "Más competiciones cada año"
    @category = :competing
    @note = "Muestra los 25 competidores españoles con más competiciones cada año."
    @table_header = { "Competiciones" => :right, "Persona" => :left }
  end

  def query
    <<-SQL
      SELECT
        YEAR(competition.start_date) AS year,
        COUNT(DISTINCT results.competition_id) AS competitions_count,
        CONCAT('[', person_name, '](https://www.worldcubeassociation.org/persons/', person_id, ')') person_link
      FROM results
      JOIN competitions competition ON competition.id = results.competition_id
      WHERE results.country_id = "Spain"
      GROUP BY year, person_id, person_name
      ORDER BY year DESC, competitions_count DESC
    SQL
  end

  def transform(query_results)
    query_results
      .group_by { |row| row["year"] }
      .map do |year, rows|
        person_rows = rows.first(25).map { |row| [row["competitions_count"], row["person_link"]] }
        [year, person_rows]
      end
  end
end

require_relative "../core/statistic"

class HighestPossibleNumberOfSolvesAtOneCompetition < Statistic
  def initialize
    @title = "Mayor número posible de resoluciones en una competición"
    @category = :competitions
    @note = "Suma las resoluciones esperadas de todas las rondas celebradas en la competición."
    @table_header = { "Resoluciones" => :right, "Competición" => :left, "Rondas" => :right }
  end

  def query
    <<-SQL
      SELECT
        SUM(format.expected_solve_count) possible_solves,
        CONCAT('[', competition.cell_name, '](https://www.worldcubeassociation.org/competitions/', competition.id, ')') competition_link,
        COUNT(*) rounds
      FROM (
        -- Every held round has a first-place result. Starting from winners avoids
        -- deduplicating the results of every competitor in the round.
        SELECT DISTINCT competition_id, event_id, round_type_id, format_id
        FROM results
        WHERE pos = 1
      ) AS competition_rounds
      JOIN formats format
        ON format.id = competition_rounds.format_id
        AND format.expected_solve_count > 0
      JOIN competitions competition ON competition.id = competition_rounds.competition_id AND competition.country_id="Spain"
      GROUP BY competition.id, competition.cell_name
      ORDER BY possible_solves DESC, rounds DESC, competition.start_date, competition.id
      LIMIT 50
    SQL
  end

  def transform(query_results)
    query_results.map do |result|
      [result["possible_solves"], result["competition_link"], result["rounds"]]
    end
  end
end

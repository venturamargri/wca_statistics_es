require_relative "../core/statistic"

class BestPotentialFmcMean < Statistic
  def initialize
    @title = "Mejor media potencial de FMC"
    @category = :results
    @note = "Calculada tomando el mejor resultado español de cada uno de los 3 intentos en una misma ronda."
    @table_header = { "Media" => :center, "Intento 1" => :center, "Intento 2" => :center, "Intento 3" => :center, "Competición" => :left }
  end

  def query
    <<-SQL
      SELECT
        (best1 + best2 + best3) / 3 mean,
        best1, best2, best3,
        CONCAT('[', competition.cell_name, '](https://www.worldcubeassociation.org/competitions/', competition.id, '/results/all#e333fm', '_', round_type_id, ')') round_link
      FROM (
        SELECT
          MIN(CASE WHEN ra.attempt_number = 1 AND ra.value > 0 THEN ra.value END) best1,
          MIN(CASE WHEN ra.attempt_number = 2 AND ra.value > 0 THEN ra.value END) best2,
          MIN(CASE WHEN ra.attempt_number = 3 AND ra.value > 0 THEN ra.value END) best3,
          r.competition_id,
          r.round_type_id
        FROM results r
        JOIN result_attempts ra ON ra.result_id = r.id
        WHERE r.event_id = '333fm'
          AND r.country_id = 'Spain'
          AND ra.attempt_number IN (1,2,3)
        GROUP BY r.competition_id, r.round_type_id
      ) AS best_attempts_by_competition_and_round
      JOIN competitions competition ON competition.id = competition_id
      WHERE LEAST(best1, best2, best3) IS NOT NULL
      ORDER BY mean
      LIMIT 100
    SQL
  end

  def transform(query_results)
    query_results.map do |result|
      ["%0.2f" % result["mean"], result["best1"], result["best2"], result["best3"], result["round_link"]]
    end
  end
end

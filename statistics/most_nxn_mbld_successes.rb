require_relative "../core/statistic"

class MostNxnMbldSuccesses < Statistic
  def initialize
    @title = "Más aciertos N/N en 3x3x3 Multi-Blind"
    @category = :results
    @note = "Intentos de 3x3x3 Multi-Blind con todos los cubos resueltos (0 fallos). Mínimo 3 aciertos N/N."
    @table_header = {
      "Persona" => :left,
      "Aciertos N/N" => :right,
      "Desglose" => :left
    }
  end

  def query
    <<-SQL
      WITH nn_multis AS (
        SELECT
          p.wca_id,
          p.name,
          (
            (99 - FLOOR(ra.value / 10000000))
            + MOD(ra.value, 100)
          ) AS num_solved
        FROM results r
        JOIN result_attempts ra
          ON ra.result_id = r.id
        JOIN persons p
          ON p.wca_id = r.person_id
         AND p.sub_id = 1
         AND p.country_id = 'Spain'
        WHERE r.event_id = '333mbf'
          AND ra.value > 0
          -- Only results with 0 missed cubes.
          AND MOD(ra.value, 100) = 0
      ),

      nn_counts AS (
        SELECT
          wca_id,
          name,
          num_solved,
          COUNT(*) AS occurrences
        FROM nn_multis
        GROUP BY
          wca_id,
          name,
          num_solved
      )

      SELECT
        CONCAT('[', name, '](https://www.worldcubeassociation.org/persons/', wca_id, ')') AS name,
        SUM(occurrences) AS nn_successes,
        GROUP_CONCAT(
          CASE
            WHEN occurrences = 1
              THEN CONCAT(num_solved, '/', num_solved)
            ELSE
              CONCAT(num_solved, '/', num_solved, ' (', occurrences, ')')
          END
          ORDER BY num_solved
          SEPARATOR ', '
        ) AS breakdown
      FROM nn_counts
      GROUP BY
        wca_id,
        name
      HAVING SUM(occurrences) >= 3
      ORDER BY
        nn_successes DESC,
        MAX(num_solved) DESC,
        name
    SQL
  end
end
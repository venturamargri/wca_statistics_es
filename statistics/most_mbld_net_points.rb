require_relative "../core/statistic"

class MostMbldNetPoints < Statistic
  def initialize
    @title = "Más puntos netos acumulados en 3x3x3 Multi-Blind"
    @category = :results
    @note = "Suma histórica de los puntos netos (resueltos menos fallados) de todos los intentos válidos oficiales de 3x3x3 Multi-Blind."
    @table_header = {
      "Puntos netos" => :right,
      "Cubos resueltos" => :right,
      "Intentos válidos" => :right,
      "Persona" => :left
    }
  end

  def query
    <<-SQL
      SELECT
        SUM(99 - FLOOR(ra.value / 10000000)) AS total_points,
        SUM((99 - FLOOR(ra.value / 10000000)) + (ra.value % 100)) AS total_solved,
        COUNT(*) AS valid_attempts,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link
      FROM results r
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      JOIN result_attempts ra ON ra.result_id = r.id
      WHERE r.event_id = '333mbf'
        AND ra.value > 0
        AND ra.value < 1000000000
      GROUP BY p.wca_id, p.name
      ORDER BY total_points DESC, total_solved DESC, p.name ASC
      LIMIT 100
    SQL
  end
end

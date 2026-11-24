require_relative "../core/statistic"

class HighestDnfPercentage < Statistic
  def initialize
    @title = "Mayor porcentaje de DNF en toda la carrera"
    @category = :results
    @note = "Porcentaje de intentos DNF sobre el total de intentos disputados (excluyendo DNS). Mínimo 100 intentos oficiales."
    @table_header = {
      "% DNF" => :right,
      "DNFs" => :right,
      "Intentos" => :right,
      "Persona" => :left
    }
  end

  def query
    <<-SQL
      SELECT
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        SUM(CASE WHEN ra.value = -1 THEN 1 ELSE 0 END) AS dnf_count,
        COUNT(*) AS total_attempts
      FROM persons p
      JOIN results r ON r.person_id = p.wca_id
      JOIN result_attempts ra ON ra.result_id = r.id
      WHERE p.sub_id = 1
        AND p.country_id = 'Spain'
        AND (ra.value > 0 OR ra.value = -1)
      GROUP BY p.wca_id, p.name
      HAVING total_attempts >= 100
      ORDER BY (dnf_count / total_attempts) DESC, dnf_count DESC, p.name ASC
      LIMIT 100
    SQL
  end

  def transform(query_results)
    query_results.map do |r|
      pct = format("%.2f%%", (r["dnf_count"].to_f / r["total_attempts"]) * 100.0)
      [pct, r["dnf_count"], r["total_attempts"], r["person_link"]]
    end
  end
end

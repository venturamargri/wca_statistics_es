require_relative "../core/statistic"

class HighestPercentageForeignCompetitions < Statistic
  def initialize
    @title = "Mayor porcentaje de competiciones en el extranjero"
    @category = :competing
    @note = "Porcentaje de competiciones disputadas fuera de España sobre el total de competiciones oficiales. Mínimo 10 competiciones (se excluyen competiciones multisede internacionales)."
    @table_header = {
      "% Extranjero" => :right,
      "Fuera de España" => :right,
      "Total" => :right,
      "Persona" => :left
    }
  end

  def query
    <<-SQL
      WITH person_comps AS (
        SELECT DISTINCT
          r.person_id,
          r.competition_id,
          c.country_id
        FROM results r
        JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
        JOIN competitions c ON c.id = r.competition_id
        WHERE c.country_id NOT LIKE 'X%'
      )
      SELECT
        SUM(CASE WHEN pc.country_id != 'Spain' THEN 1 ELSE 0 END) AS foreign_comps,
        COUNT(*) AS total_comps,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link
      FROM person_comps pc
      JOIN persons p ON p.wca_id = pc.person_id AND p.sub_id = 1
      GROUP BY p.wca_id, p.name
      HAVING total_comps >= 10 AND foreign_comps > 0
      ORDER BY (foreign_comps / total_comps) DESC, foreign_comps DESC, p.name ASC
      LIMIT 100
    SQL
  end

  def transform(query_results)
    query_results.map do |r|
      pct = format("%.2f%%", (r["foreign_comps"].to_f / r["total_comps"]) * 100.0)
      [pct, r["foreign_comps"], r["total_comps"], r["person_link"]]
    end
  end
end

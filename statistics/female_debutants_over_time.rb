require_relative "../core/statistic"

class FemaleDebutantsOverTime < Statistic
  def initialize
    @title = "Porcentaje de nuevas debutantes por año"
    @category = :competing
    @note = "Porcentaje de mujeres sobre el total de competidores españoles que debutaron en la WCA cada año (según el año de su WCA ID, independientemente del país de debut)."
    @table_header = {
      "Año" => :center,
      "%" => :right
    }
  end

  def query
    <<-SQL
      SELECT
        CAST(LEFT(p.wca_id, 4) AS UNSIGNED) AS debut_year,
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS female_count,
        COUNT(*) AS total_count
      FROM persons p
      WHERE p.sub_id = 1
        AND p.country_id = 'Spain'
      GROUP BY debut_year
      ORDER BY debut_year DESC
    SQL
  end

  def transform(query_results)
    query_results.map do |r|
      pct = (r["female_count"].to_f / r["total_count"].to_f) * 100.0
      [r["debut_year"].to_i, format("%.2f%%", pct)]
    end
  end
end

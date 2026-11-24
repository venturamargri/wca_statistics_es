require_relative "../core/statistic"

class FemaleParticipationOverTime < Statistic
  def initialize
    @title = "Porcentaje de participación femenina a través del tiempo"
    @category = :competitions
    @note = "Porcentaje de asistencias femeninas sobre el total de asistencias (de cualquier nacionalidad) en competiciones oficiales celebradas en España cada año. Cada competición a la que asiste una persona cuenta como una participación."
    @table_header = {
      "Año" => :center,
      "%" => :right
    }
  end

  def query
    <<-SQL
      WITH comp_attendances AS (
        SELECT DISTINCT
          YEAR(c.start_date) AS comp_year,
          r.competition_id,
          r.person_id
        FROM results r
        JOIN competitions c ON c.id = r.competition_id
        WHERE c.country_id = 'Spain'
      )
      SELECT
        ca.comp_year,
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS female_count,
        COUNT(*) AS total_count
      FROM comp_attendances ca
      JOIN persons p ON p.wca_id = ca.person_id AND p.sub_id = 1
      GROUP BY ca.comp_year
      ORDER BY ca.comp_year DESC
    SQL
  end

  def transform(query_results)
    query_results.map do |r|
      pct = (r["female_count"].to_f / r["total_count"].to_f) * 100.0
      [r["comp_year"].to_i, format("%.2f%%", pct)]
    end
  end
end

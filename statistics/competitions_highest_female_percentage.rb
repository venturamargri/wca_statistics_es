require_relative "../core/statistic"

class CompetitionsHighestFemalePercentage < Statistic
  def initialize
    @title = "Competiciones con mayor porcentaje de participación femenina"
    @category = :competitions
    @note = "Top 30 de competiciones celebradas en España (mínimo 15 competidores de cualquier nacionalidad) con mayor porcentaje de participación femenina sobre el total de asistentes."
    @table_header = {
      "%" => :right,
      "Mujeres" => :right,
      "Total" => :right,
      "Competición" => :left
    }
  end

  def query
    <<-SQL
      WITH comp_people AS (
        SELECT DISTINCT
          r.competition_id,
          r.person_id
        FROM results r
        JOIN competitions c ON c.id = r.competition_id
        WHERE c.country_id = 'Spain'
      )
      SELECT
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS female_count,
        COUNT(*) AS total_count,
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, ')') AS comp_link
      FROM comp_people cp
      JOIN persons p ON p.wca_id = cp.person_id AND p.sub_id = 1
      JOIN competitions c ON c.id = cp.competition_id
      GROUP BY c.id, c.cell_name, c.start_date
      HAVING COUNT(*) >= 15
      ORDER BY (SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) / COUNT(*)) DESC, female_count DESC, total_count DESC, c.start_date DESC
      LIMIT 30
    SQL
  end

  def transform(query_results)
    query_results.map do |r|
      female = r["female_count"].to_i
      total = r["total_count"].to_i
      pct = (female.to_f / total.to_f) * 100.0
      [
        format("%.2f%%", pct),
        female,
        total,
        r["comp_link"]
      ]
    end
  end
end

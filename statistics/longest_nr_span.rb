require_relative "../core/statistic"
require_relative "../core/spanish_format"

class LongestNrSpan < Statistic
  def initialize
    @title = "Mayor tiempo entre el primer y el último Récord Nacional (NR)"
    @category = :records
    @note = "Tiempo transcurrido entre el primer y el último récord (NR, ER o WR) conseguido representando a España."
    @table_header = {
      "Años" => :right,
      "Días" => :right,
      "Persona" => :left,
      "Primer NR" => :left,
      "Último NR" => :left,
      "Total NRs" => :right
    }
  end

  def query
    <<-SQL
      SELECT
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        MIN(c.start_date) AS first_nr_date,
        MAX(c.start_date) AS last_nr_date,
        DATEDIFF(MAX(c.start_date), MIN(c.start_date)) AS days_span,
        SUM(
          (CASE WHEN r.regional_single_record IS NOT NULL AND r.regional_single_record != '' THEN 1 ELSE 0 END) +
          (CASE WHEN r.regional_average_record IS NOT NULL AND r.regional_average_record != '' THEN 1 ELSE 0 END)
        ) AS total_nrs
      FROM results r
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      JOIN competitions c ON c.id = r.competition_id
      WHERE r.country_id = 'Spain'
        AND (
          (r.regional_single_record IS NOT NULL AND r.regional_single_record != '')
          OR (r.regional_average_record IS NOT NULL AND r.regional_average_record != '')
        )
      GROUP BY p.wca_id, p.name
      HAVING days_span > 0
      ORDER BY days_span DESC, total_nrs DESC, p.name ASC
      LIMIT 100
    SQL
  end

  def transform(query_results)
    query_results.map do |r|
      years = format("%.2f", r["days_span"].to_f / 365.25)
      [
        years,
        r["days_span"],
        r["person_link"],
        SpanishFormat.short_date(r["first_nr_date"]),
        SpanishFormat.short_date(r["last_nr_date"]),
        r["total_nrs"]
      ]
    end
  end
end

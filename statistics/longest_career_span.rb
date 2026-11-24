require_relative "../core/statistic"
require_relative "../core/spanish_format"

class LongestCareerSpan < Statistic
  def initialize
    @title = "Carreras más longevas"
    @category = :competing
    @note = "Mayor tiempo transcurrido entre la primera y la última competición oficial disputada por competidores españoles."
    @table_header = {
      "Años" => :right,
      "Días" => :right,
      "Persona" => :left,
      "Primera comp." => :left,
      "Última comp." => :left,
      "Competiciones" => :right
    }
  end

  def query
    <<-SQL
      SELECT
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        MIN(c.start_date) AS first_date,
        MAX(c.end_date) AS last_date,
        DATEDIFF(MAX(c.end_date), MIN(c.start_date)) AS days_span,
        COUNT(DISTINCT r.competition_id) AS comps_count
      FROM results r
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      JOIN competitions c ON c.id = r.competition_id
      GROUP BY p.wca_id, p.name
      HAVING comps_count >= 2
      ORDER BY days_span DESC, comps_count DESC, p.name ASC
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
        SpanishFormat.short_date(r["first_date"]),
        SpanishFormat.short_date(r["last_date"]),
        r["comps_count"]
      ]
    end
  end
end

require_relative "../core/grouped_statistic"
require_relative "../core/events"

class DebutYearDistribution < GroupedStatistic
  CURRENT_EVENTS = %w[333 222 444 555 666 777 333bf 333fm 333oh clock minx pyram skewb sq1 444bf 555bf 333mbf].freeze
  AVG_EVENTS = %w[333 222 444 555 666 777 333fm 333oh clock minx pyram skewb sq1].freeze
  SGL_EVENTS = %w[333bf 444bf 555bf 333mbf].freeze

  def initialize
    @title = "Distribución por año de debut del Top 100 de España"
    @category = :competing
    @note = "Año de debut (según el WCA ID) de los 100 mejores competidores españoles vigentes en cada una de las 17 categorías oficiales actuales (usando el formato principal WCA), ordenado de más a menos competidores."
    @table_header = {
      "Año de debut" => :center,
      "Competidores" => :right,
      "%" => :right,
      "Mejor clasificado" => :left
    }
  end

  def query
    avg_list = AVG_EVENTS.map { |e| "'#{e}'" }.join(", ")
    sgl_list = SGL_EVENTS.map { |e| "'#{e}'" }.join(", ")
    <<-SQL
      SELECT
        ra.event_id,
        ra.person_id,
        ra.country_rank,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link
      FROM ranks_average ra
      JOIN persons p ON p.wca_id = ra.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      WHERE ra.event_id IN (#{avg_list})
        AND ra.country_rank <= 100

      UNION ALL

      SELECT
        rs.event_id,
        rs.person_id,
        rs.country_rank,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link
      FROM ranks_single rs
      JOIN persons p ON p.wca_id = rs.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      WHERE rs.event_id IN (#{sgl_list})
        AND rs.country_rank <= 100
    SQL
  end

  def transform(query_results)
    by_event = query_results.group_by { |r| r["event_id"] }

    CURRENT_EVENTS.map do |event_id|
      event_name = Events::ALL[event_id] || event_id
      rows = by_event[event_id] || []
      total = rows.size
      next [event_name, []] if total == 0

      table = rows
        .group_by { |r| r["person_id"][0, 4] }
        .map do |year, group|
          best = group.min_by { |r| [r["country_rank"].to_i, r["person_link"]] }
          {
            year: year,
            count: group.size,
            pct: format("%.1f%%", (group.size.to_f / total) * 100.0),
            best_label: "##{best['country_rank']} #{best['person_link']}"
          }
        end
        .sort_by { |x| [-x[:count], -x[:year].to_i] }
        .map { |x| [x[:year], x[:count], x[:pct], x[:best_label]] }

      [event_name, table]
    end.reject { |_, rows| rows.empty? }
  end
end
# v2

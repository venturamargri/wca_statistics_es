require_relative "../core/statistic"
require_relative "../core/events"

class MostEventsWithGold < Statistic
  CURRENT_EVENTS = %w[333 222 444 555 666 777 333bf 333fm 333oh clock minx pyram skewb sq1 444bf 555bf 333mbf].freeze

  def initialize
    @title = "Más categorías distintas con oro"
    @category = :podiums
    @note = "Competidores españoles que han ganado al menos una final en el mayor número de categorías oficiales actuales (sobre 17)."
    @table_header = {
      "Categorías" => :right,
      "Persona" => :left,
      "Total oros" => :right,
      "Categorías ganadas" => :left
    }
  end

  def query
    event_list = CURRENT_EVENTS.map { |e| "'#{e}'" }.join(", ")
    <<-SQL
      SELECT
        COUNT(DISTINCT r.event_id) AS events_with_gold,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        COUNT(*) AS total_golds,
        GROUP_CONCAT(DISTINCT r.event_id SEPARATOR ',') AS event_ids
      FROM results r
      JOIN round_types rt ON rt.id = r.round_type_id AND rt.final = 1
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      WHERE r.pos = 1
        AND r.best > 0
        AND r.event_id IN (#{event_list})
      GROUP BY p.wca_id, p.name
      ORDER BY events_with_gold DESC, total_golds DESC, p.name ASC
      LIMIT 50
    SQL
  end

  def transform(query_results)
    total_events = CURRENT_EVENTS.size
    query_results.map do |r|
      won_set = r["event_ids"].split(",")
      ordered_names = CURRENT_EVENTS
        .select { |id| won_set.include?(id) }
        .map { |id| Events::ALL[id] || id }
        .join(", ")
      ["#{r['events_with_gold']} / #{total_events}", r["person_link"], r["total_golds"], ordered_names]
    end
  end
end

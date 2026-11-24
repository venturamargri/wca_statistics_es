require_relative "../core/statistic"
require_relative "../core/events"

class BestWorstNationalRank < Statistic
  AVG_EVENTS = %w[333 222 444 555 666 777 333fm 333oh clock minx pyram skewb sq1].freeze
  SGL_EVENTS = %w[333bf 444bf 555bf 333mbf].freeze
  ALL_EVENTS = (AVG_EVENTS + SGL_EVENTS).freeze

  def initialize
    @title = "El suelo del all-rounder (mejor peor ranking nacional)"
    @category = :results
    @note = "Competidores españoles ordenados según su peor posición nacional (NR más alto) entre las 17 categorías actuales (formato principal WCA: average en 13 y single en las 4 a ciegas). En las categorías sin marca oficial se asigna el puesto penalizado (total de españoles clasificados + 1)."
    @table_header = {
      "Persona" => :left,
      "Peor ranking" => :right,
      "Categoría" => :left
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

      UNION ALL

      SELECT
        rs.event_id,
        rs.person_id,
        rs.country_rank,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link
      FROM ranks_single rs
      JOIN persons p ON p.wca_id = rs.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      WHERE rs.event_id IN (#{sgl_list})
    SQL
  end

  def transform(query_results)
    event_counts = Hash.new(0)
    person_ranks = Hash.new { |h, k| h[k] = {} }
    person_links = {}

    query_results.each do |r|
      ev = r["event_id"]
      pid = r["person_id"]
      event_counts[ev] += 1
      person_ranks[pid][ev] = r["country_rank"].to_i
      person_links[pid] = r["person_link"]
    end

    penalties = ALL_EVENTS.to_h { |e| [e, event_counts[e] + 1] }

    person_ranks
      .map do |pid, ranks_by_event|
        worst_rank = 0
        sor = 0
        worst_events = []

        ALL_EVENTS.each do |e|
          if ranks_by_event.key?(e)
            r = ranks_by_event[e]
            label = Events::ALL[e] || e
          else
            r = penalties[e]
            label = "#{Events::ALL[e] || e} (sin marca)"
          end

          sor += r
          if r > worst_rank
            worst_rank = r
            worst_events = [label]
          elsif r == worst_rank
            worst_events << label
          end
        end

        {
          person_link: person_links[pid],
          worst_rank: worst_rank,
          worst_events: worst_events.join(", "),
          events_count: ranks_by_event.size,
          sor: sor
        }
      end
      .sort_by { |x| [x[:worst_rank], x[:sor], -x[:events_count], x[:person_link]] }
      .first(50)
      .map { |x| [x[:person_link], x[:worst_rank], x[:worst_events]] }
  end
end

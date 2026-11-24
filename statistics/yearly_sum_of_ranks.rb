require_relative "../core/grouped_statistic"
require_relative "../core/events"

class YearlySumOfRanks < GroupedStatistic
  def initialize
    @title = "Clasificación Sum of Ranks (SoR) por año"
    @category = :results
    @note = "Sum of Ranks anual usando únicamente las marcas del formato principal WCA logradas ese año. En las categorías oficiales vigentes de ese año en las que no se registró marca, se asigna el puesto (total de clasificados españoles ese año + 1)."
    @table_header = {
      "Persona" => :left,
      "Sum of Ranks" => :right
    }
  end

  def query
    event_list = Events::ALL.keys.map { |e| "'#{e}'" }.join(", ")
    <<-SQL
      SELECT
        YEAR(c.start_date) AS year,
        r.event_id,
        r.person_id,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        MIN(CASE
          WHEN r.event_id IN ('333bf', '444bf', '555bf', '333mbf') THEN IF(r.best > 0, r.best, NULL)
          ELSE IF(r.average > 0, r.average, NULL)
        END) AS best_mark
      FROM results r
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      JOIN competitions c ON c.id = r.competition_id
      WHERE r.event_id IN (#{event_list})
      GROUP BY YEAR(c.start_date), r.event_id, r.person_id, p.name, p.wca_id
      HAVING best_mark IS NOT NULL
    SQL
  end

  def transform(query_results)
    by_year = query_results.group_by { |r| r["year"] }

    by_year.keys.sort.reverse.map do |year|
      year_rows = by_year[year]
      by_event = year_rows.group_by { |r| r["event_id"] }
      active_events = by_event.keys

      person_links = {}
      event_ranks = {}
      event_penalties = {}

      by_event.each do |event_id, rows|
        sorted = rows.sort_by { |r| r["best_mark"] }
        ranks = {}
        prev_val = nil
        prev_rank = 0
        sorted.each_with_index do |r, idx|
          person_links[r["person_id"]] = r["person_link"]
          rank = (r["best_mark"] == prev_val) ? prev_rank : (idx + 1)
          ranks[r["person_id"]] = rank
          prev_val = r["best_mark"]
          prev_rank = rank
        end
        event_ranks[event_id] = ranks
        event_penalties[event_id] = sorted.size + 1
      end

      table = person_links.keys
        .map do |pid|
          sor = 0
          cnt = 0
          active_events.each do |e|
            if event_ranks[e].key?(pid)
              sor += event_ranks[e][pid]
              cnt += 1
            else
              sor += event_penalties[e]
            end
          end
          [pid, sor, cnt]
        end
        .sort_by { |pid, sor, cnt| [sor, -cnt, person_links[pid]] }
        .first(20)
        .map { |pid, sor, cnt| [person_links[pid], sor, "#{cnt}/#{active_events.size}"] }

      [year.to_s, table]
    end
  end
  def data
    @filtered_data ||= super.map do |group, rows|
      [group, rows.map { |r| r.each_with_index.reject { |_, i| i == 2 }.map(&:first) }]
    end
  end

end

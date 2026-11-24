require_relative "../core/grouped_statistic"
require_relative "../core/events"

class YearlyKinchRanks < GroupedStatistic
  SINGLE_EVENTS = %w[333bf 444bf 555bf 333mbf].freeze

  def initialize
    @title = "Clasificación Kinch por año"
    @category = :results
    @note = "Ranking Kinch calculado anualmente usando únicamente las marcas del formato principal WCA conseguidas en ese año, comparadas frente a la mejor marca española de ese mismo año (sobre las categorías oficiales con resultados españoles en dicho año)."
    @table_header = {
      "Persona" => :left,
      "Kinch" => :right
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

  def mbld_kinch_value(val)
    points = 99 - (val / 10_000_000)
    time_sec = (val / 100) % 100_000
    time_bonus = time_sec >= 3600 ? 0.0 : (3600.0 - time_sec) / 3600.0
    points + time_bonus
  end

  def transform(query_results)
    by_year = query_results.group_by { |r| r["year"] }

    by_year.keys.sort.reverse.map do |year|
      year_rows = by_year[year]
      by_event = year_rows.group_by { |r| r["event_id"] }
      num_events = by_event.size

      person_links = {}
      person_scores = Hash.new(0.0)
      person_counts = Hash.new(0)

      by_event.each do |event_id, rows|
        if event_id == "333mbf"
          values = rows.map { |r| [r, mbld_kinch_value(r["best_mark"])] }
          best_val = values.map(&:last).max
          next if best_val <= 0

          values.each do |r, val|
            pid = r["person_id"]
            person_links[pid] = r["person_link"]
            person_scores[pid] += (val / best_val) * 100.0
            person_counts[pid] += 1
          end
        else
          best_val = rows.map { |r| r["best_mark"] }.min.to_f
          rows.each do |r|
            pid = r["person_id"]
            person_links[pid] = r["person_link"]
            person_scores[pid] += (best_val / r["best_mark"].to_f) * 100.0
            person_counts[pid] += 1
          end
        end
      end

      table = person_scores
        .map { |pid, total| [pid, total / num_events, person_counts[pid]] }
        .sort_by { |pid, kinch, _| [-kinch, person_links[pid]] }
        .first(20)
        .map { |pid, kinch, cnt| [person_links[pid], format("%.2f", kinch), "#{cnt}/#{num_events}"] }

      [year.to_s, table]
    end
  end
  def data
    @filtered_data ||= super.map do |group, rows|
      [group, rows.map { |r| r.each_with_index.reject { |_, i| i == 2 }.map(&:first) }]
    end
  end

end

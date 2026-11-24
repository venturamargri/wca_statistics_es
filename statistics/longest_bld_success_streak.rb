require_relative "../core/grouped_statistic"
require_relative "../core/events"
require_relative "../core/spanish_format"

class LongestBldSuccessStreak < GroupedStatistic
  BLD_EVENTS = %w[333bf 444bf 555bf 333mbf].freeze

  def initialize
    @title = "Mayor racha de éxitos seguidos a ciegas"
    @category = :results
    @note = "Mayor número de intentos oficiales válidos consecutivos (sin DNF; los DNS se ignoran) en cada categoría a ciegas. Mínimo 2 éxitos seguidos; se muestra la mejor racha de cada persona."
    @table_header = {
      "Racha" => :right,
      "Persona" => :left,
      "Inicio" => :left,
      "Fin" => :left
    }
  end

  def query
    event_list = BLD_EVENTS.map { |e| "'#{e}'" }.join(", ")
    <<-SQL
      SELECT
        r.event_id,
        r.person_id,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        ra.value,
        c.start_date
      FROM results r
      JOIN result_attempts ra ON ra.result_id = r.id
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      JOIN competitions c ON c.id = r.competition_id
      JOIN round_types rt ON rt.id = r.round_type_id
      WHERE r.event_id IN (#{event_list})
        AND (ra.value > 0 OR ra.value = -1)
      ORDER BY c.start_date ASC, c.id ASC, rt.rank ASC, ra.attempt_number ASC
    SQL
  end

  def transform(query_results)
    by_event = query_results.group_by { |r| r["event_id"] }

    BLD_EVENTS.map do |event_id|
      event_name = Events::ALL[event_id] || event_id
      event_rows = by_event[event_id] || []
      streaks = []

      event_rows.group_by { |r| r["person_id"] }.each do |_, attempts|
        best_len = 0
        best_start = nil
        best_end = nil
        best_ongoing = false

        cur_len = 0
        cur_start = nil
        cur_end = nil

        attempts.each do |a|
          if a["value"].to_i > 0
            cur_start = a["start_date"] if cur_len == 0
            cur_len += 1
            cur_end = a["start_date"]
          else
            if cur_len > best_len
              best_len = cur_len
              best_start = cur_start
              best_end = cur_end
              best_ongoing = false
            end
            cur_len = 0
            cur_start = nil
            cur_end = nil
          end
        end

        if cur_len > 0 && cur_len >= best_len
          best_len = cur_len
          best_start = cur_start
          best_end = cur_end
          best_ongoing = true
        end

        next if best_len < 2

        streaks << {
          len: best_len,
          person_link: attempts.first["person_link"],
          start_date: best_start,
          end_date: best_end,
          ongoing: best_ongoing
        }
      end

      table = streaks
        .sort_by { |s| [-s[:len], s[:ongoing] ? 0 : 1, s[:person_link]] }
        .first(15)
        .map do |s|
          end_label = s[:ongoing] ? "#{SpanishFormat.short_date(s[:end_date])} (en curso)" : SpanishFormat.short_date(s[:end_date])
          [s[:len], s[:person_link], SpanishFormat.short_date(s[:start_date]), end_label]
        end

      [event_name, table]
    end.reject { |_, rows| rows.empty? }
  end
end
# v2

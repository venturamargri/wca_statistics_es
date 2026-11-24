require_relative "../core/grouped_statistic"
require_relative "../core/events"
require_relative "../core/spanish_format"

class LongestFinalsWinStreak < GroupedStatistic
  def initialize
    @title = "Racha más larga invicto en finales de una categoría"
    @category = :podiums
    @note = "Mayor número de finales consecutivas ganadas por un competidor español en la misma categoría (mínimo 2 victorias seguidas). Se muestra la mejor racha de cada persona por categoría."
    @table_header = {
      "Racha" => :right,
      "Persona" => :left,
      "Inicio" => :left,
      "Fin" => :left
    }
  end

  def query
    event_list = Events::ALL.keys.map { |e| "'#{e}'" }.join(", ")
    <<-SQL
      SELECT
        r.event_id,
        r.person_id,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        r.pos,
        r.best,
        c.start_date,
        c.end_date,
        c.id AS comp_id
      FROM results r
      JOIN round_types rt ON rt.id = r.round_type_id AND rt.final = 1
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      JOIN competitions c ON c.id = r.competition_id
      WHERE r.event_id IN (#{event_list})
      ORDER BY c.start_date ASC, c.end_date ASC, c.id ASC
    SQL
  end

  def transform(query_results)
    by_event = query_results.group_by { |r| r["event_id"] }

    Events::ALL.map do |event_id, event_name|
      event_rows = by_event[event_id] || []
      streaks = []

      event_rows.group_by { |r| r["person_id"] }.each do |_, finals|
        best_len = 0
        best_start = nil
        best_end = nil
        best_ongoing = false

        cur_len = 0
        cur_start = nil
        cur_end = nil

        finals.each do |f|
          if f["pos"] == 1 && f["best"] > 0
            cur_start = f["start_date"] if cur_len == 0
            cur_len += 1
            cur_end = f["start_date"]
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

        if cur_len > best_len || (cur_len == best_len && cur_len > 0)
          best_len = cur_len
          best_start = cur_start
          best_end = cur_end
          best_ongoing = true
        end

        next if best_len < 2

        streaks << {
          len: best_len,
          person_link: finals.first["person_link"],
          start_date: best_start,
          end_date: best_end,
          ongoing: best_ongoing
        }
      end

      table = streaks
        .sort_by { |s| [-s[:len], s[:ongoing] ? 0 : 1, s[:person_link]] }
        .first(10)
        .map do |s|
          end_label = s[:ongoing] ? "#{SpanishFormat.short_date(s[:end_date])} (en curso)" : SpanishFormat.short_date(s[:end_date])
          [s[:len], s[:person_link], SpanishFormat.short_date(s[:start_date]), end_label]
        end

      [event_name, table]
    end.reject { |_, rows| rows.empty? }
  end
end

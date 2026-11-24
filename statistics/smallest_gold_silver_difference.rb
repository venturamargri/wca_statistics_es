require_relative "../core/grouped_statistic"
require_relative "../core/events"
require_relative "../core/solve_time"

class SmallestGoldSilverDifference < GroupedStatistic
  def initialize
    @title = "Menor diferencia entre el oro y la plata"
    @category = :podiums
    @note = "Finales en cualquier competición donde el 1.º y el 2.º puesto fueron conseguidos por competidores españoles. Incluye empates exactos (0.00) resueltos por single o empatados en el 1.º puesto."
    @table_header = {
      "Diferencia" => :right,
      "Oro" => :left,
      "Marca oro" => :right,
      "Plata" => :left,
      "Marca plata" => :right,
      "Competición" => :left
    }
  end

  def query
    <<-SQL
      SELECT
        r1.event_id,
        f.sort_by,
        CASE WHEN f.sort_by = 'average' THEN r1.average ELSE r1.best END AS val1,
        CASE WHEN f.sort_by = 'average' THEN r2.average ELSE r2.best END AS val2,
        CASE WHEN f.sort_by = 'average' THEN (r2.average - r1.average) ELSE (r2.best - r1.best) END AS diff,
        CONCAT('[', p1.name, '](https://www.worldcubeassociation.org/persons/', p1.wca_id, ')') AS gold_link,
        CONCAT('[', p2.name, '](https://www.worldcubeassociation.org/persons/', p2.wca_id, ')') AS silver_link,
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, '/results/all#e', r1.event_id, '_', r1.round_type_id, ')') AS comp_link,
        c.start_date
      FROM results r1
      JOIN round_types rt ON rt.id = r1.round_type_id AND rt.final = 1
      JOIN results r2
        ON r2.competition_id = r1.competition_id
        AND r2.event_id = r1.event_id
        AND r2.round_type_id = r1.round_type_id
        AND ((r1.pos = 1 AND r2.pos = 2) OR (r1.pos = 1 AND r2.pos = 1 AND r1.person_id < r2.person_id))
      JOIN persons p1 ON p1.wca_id = r1.person_id AND p1.sub_id = 1 AND p1.country_id = 'Spain'
      JOIN persons p2 ON p2.wca_id = r2.person_id AND p2.sub_id = 1 AND p2.country_id = 'Spain'
      JOIN competitions c ON c.id = r1.competition_id
      JOIN formats f ON f.id = r1.format_id
      WHERE r1.pos = 1
        AND (
          (f.sort_by = 'average' AND r1.average > 0 AND r2.average > 0 AND r2.average >= r1.average)
          OR (f.sort_by = 'single' AND r1.best > 0 AND r2.best > 0 AND r2.best >= r1.best)
        )
    SQL
  end

  def format_diff(event_id, sort_by, diff, val1, val2)
    if event_id == "333mbf"
      pts1 = 99 - (val1 / 10_000_000)
      sec1 = (val1 / 100) % 100_000
      pts2 = 99 - (val2 / 10_000_000)
      sec2 = (val2 / 100) % 100_000
      dp = pts1 - pts2
      dt = sec2 - sec1
      if dp == 0 && dt == 0
        "0 ptos (empate)"
      elsif dp == 0
        "0 ptos, #{dt}s"
      else
        "#{dp} #{dp == 1 ? 'pto' : 'ptos'}"
      end
    elsif event_id == "333fm"
      sort_by == "single" ? "#{diff} mov." : format("%.2f", diff / 100.0)
    else
      mins = diff / 6000
      secs = (diff % 6000) / 100.0
      mins > 0 ? format("%d:%05.2f", mins, secs) : format("%.2f", secs)
    end
  end

  def transform(query_results)
    Events::ALL.map do |event_id, event_name|
      results = query_results
        .select { |r| r["event_id"] == event_id }
        .sort_by { |r| [r["diff"], r["val1"], r["start_date"]] }
        .first(10)
        .map do |r|
          metric = r["sort_by"].to_sym
          [
            format_diff(event_id, r["sort_by"], r["diff"], r["val1"], r["val2"]),
            r["gold_link"],
            SolveTime.new(event_id, metric, r["val1"]).clock_format,
            r["silver_link"],
            SolveTime.new(event_id, metric, r["val2"]).clock_format,
            r["comp_link"]
          ]
        end
      [event_name, results]
    end.reject { |_, rows| rows.empty? }
  end
end

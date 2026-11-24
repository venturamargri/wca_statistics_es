require_relative "../core/statistic"

class FastestFillingCompetitions < Statistic
  def initialize
    @title = "Competiciones en España que llenaron plazas más rápido"
    @category = :competitions
    @note = "Tiempo transcurrido desde la apertura oficial de inscripciones hasta alcanzarse el límite de plazas (mínimo 15 plazas, solo competiciones ya celebradas)."
    @table_header = {
      "Tiempo en llenarse" => :right,
      "Plazas" => :right,
      "Competición" => :left,
      "Apertura (UTC)" => :left
    }
  end

  def query
    <<-SQL
      WITH ranked_regs AS (
        SELECT
          reg.competition_id,
          reg.created_at,
          ROW_NUMBER() OVER (PARTITION BY reg.competition_id ORDER BY reg.created_at ASC, reg.id ASC) AS rn
        FROM registrations reg
        JOIN competitions c ON c.id = reg.competition_id
        WHERE c.country_id = 'Spain'
          AND c.competitor_limit_enabled = 1
          AND c.competitor_limit >= 15
          AND c.registration_open IS NOT NULL
          AND EXISTS (SELECT 1 FROM results r WHERE r.competition_id = c.id)
      )
      SELECT
        TIMESTAMPDIFF(SECOND, c.registration_open, rr.created_at) AS fill_seconds,
        c.competitor_limit,
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, ')') AS comp_link,
        c.registration_open
      FROM ranked_regs rr
      JOIN competitions c ON c.id = rr.competition_id
      WHERE rr.rn = c.competitor_limit
        AND TIMESTAMPDIFF(SECOND, c.registration_open, rr.created_at) > 0
      ORDER BY fill_seconds ASC, c.competitor_limit DESC
      LIMIT 50
    SQL
  end

  def format_duration(total_seconds)
    days = total_seconds / 86_400
    hours = (total_seconds % 86_400) / 3600
    mins = (total_seconds % 3600) / 60
    secs = total_seconds % 60

    if days > 0
      format("%dd %02dh %02dm", days, hours, mins)
    elsif hours > 0
      format("%dh %02dm %02ds", hours, mins, secs)
    elsif mins > 0
      format("%dm %02ds", mins, secs)
    else
      "#{secs}s"
    end
  end

  def transform(query_results)
    query_results.map do |r|
      open_str = r["registration_open"].respond_to?(:strftime) ? r["registration_open"].strftime("%Y-%m-%d %H:%M") : r["registration_open"].to_s
      [format_duration(r["fill_seconds"]), r["competitor_limit"], r["comp_link"], open_str]
    end
  end
end

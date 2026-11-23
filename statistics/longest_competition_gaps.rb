require_relative "../core/statistic"
require "date"

class LongestCompetitionGaps < Statistic
  MIN_GAP_YEARS = 5

  def initialize
    @title = "Mayores intervalos entre competiciones"
    @category = :competing
    @note = "Solo incluye competidores españoles. Muestra la mayor pausa de al menos #{MIN_GAP_YEARS} años entre dos competiciones consecutivas."
    @table_header = { "Intervalo" => :right, "Persona" => :left, "Desde" => :left, "Hasta" => :left }
  end

  def query
    <<-SQL
      WITH attended AS (
        SELECT DISTINCT
          person.wca_id,
          person.name,
          competition.id AS competition_id,
          competition.cell_name,
          competition.start_date
        FROM results
        JOIN persons person ON person.wca_id = results.person_id AND person.sub_id = 1 AND person.country_id = 'Spain'
        JOIN competitions competition ON competition.id = results.competition_id
      ),
      gaps AS (
        SELECT
          attended.*,
          LAG(competition_id) OVER w AS previous_competition_id,
          LAG(cell_name) OVER w AS previous_cell_name,
          LAG(start_date) OVER w AS previous_start_date
        FROM attended
        WINDOW w AS (PARTITION BY wca_id ORDER BY start_date, competition_id)
      ),
      longest_gaps AS (
        SELECT
          gaps.*,
          DATEDIFF(start_date, previous_start_date) AS gap_days,
          ROW_NUMBER() OVER (PARTITION BY wca_id ORDER BY DATEDIFF(start_date, previous_start_date) DESC, previous_start_date) AS rn
        FROM gaps
        WHERE previous_start_date IS NOT NULL
      )
      SELECT
        previous_start_date,
        start_date,
        CONCAT('[', name, '](https://www.worldcubeassociation.org/persons/', wca_id, ')') AS person_link,
        CONCAT('[', previous_cell_name, '](https://www.worldcubeassociation.org/competitions/', previous_competition_id, ')') AS from_competition_link,
        CONCAT('[', cell_name, '](https://www.worldcubeassociation.org/competitions/', competition_id, ')') AS to_competition_link
      FROM longest_gaps
      WHERE rn = 1 AND start_date >= previous_start_date + INTERVAL #{MIN_GAP_YEARS} YEAR
      ORDER BY gap_days DESC, name
    SQL
  end

  def transform(query_results)
    query_results.map do |result|
      [
        format_gap(result["previous_start_date"], result["start_date"]),
        result["person_link"],
        result["from_competition_link"],
        result["to_competition_link"]
      ]
    end
  end

  private

  # Formats the period between two dates as "X years X months X days", counting whole months first.
  def format_gap(from, to)
    months = (to.year - from.year) * 12 + (to.month - from.month)
    months -= 1 if (from >> months) > to
    years, remaining_months = months.divmod(12)
    days = (to - (from >> months)).to_i
    [pluralize(years, "año", "años"), pluralize(remaining_months, "mes", "meses"), pluralize(days, "día", "días")].join(" ")
  end

  def pluralize(count, singular, plural)
    "#{count} #{count == 1 ? singular : plural}"
  end
end

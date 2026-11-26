require_relative "../core/statistic"
require_relative "../core/events"

class SlowestFirstNr < Statistic
  RETIRED_EVENTS = {
    "333ft" => "3x3x3 With Feet",
    "333mbo" => "3x3x3 Multi-Blind Old Style",
    "magic" => "Magic",
    "mmagic" => "Master Magic"
  }.freeze

  def initialize
    @title = "Mayor tiempo en conseguir el primer Récord Nacional"
    @category = :records
    @note = "Días transcurridos desde la fecha de inicio de la primera competición oficial hasta el primer Récord Nacional (NR, ER o WR en cualquier categoría, single o average) para quienes tardaron más de 3 años (> 1.095 días)."
    @table_header = {
      "Persona" => :left,
      "Días" => :right,
      "Competición" => :left,
      "Categoría" => :left
    }
  end

  def query
    <<-SQL
      WITH spanish_nrs AS (
        SELECT
          r.person_id,
          r.competition_id,
          r.event_id,
          c.start_date AS nr_date,
          c.cell_name AS comp_name
        FROM results r
        JOIN competitions c ON c.id = r.competition_id
        WHERE r.country_id = 'Spain'
          AND (
            r.regional_single_record IN ('NR', 'ER', 'WR')
            OR r.regional_average_record IN ('NR', 'ER', 'WR')
          )
      ),
      first_nr_date AS (
        SELECT
          person_id,
          MIN(nr_date) AS first_nr_date
        FROM spanish_nrs
        GROUP BY person_id
      ),
      first_comp AS (
        SELECT
          r.person_id,
          MIN(c.start_date) AS first_date
        FROM results r
        JOIN first_nr_date fn ON fn.person_id = r.person_id
        JOIN competitions c ON c.id = r.competition_id
        GROUP BY r.person_id
      )
      SELECT
        p.wca_id,
        p.name AS person_name,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        DATEDIFF(sn.nr_date, fc.first_date) AS days,
        sn.nr_date,
        CONCAT('[', sn.comp_name, '](https://www.worldcubeassociation.org/competitions/', sn.competition_id, ')') AS comp_link,
        sn.event_id
      FROM spanish_nrs sn
      JOIN first_nr_date fn
        ON fn.person_id = sn.person_id
       AND fn.first_nr_date = sn.nr_date
      JOIN first_comp fc ON fc.person_id = sn.person_id
      JOIN persons p ON p.wca_id = sn.person_id AND p.sub_id = 1
      WHERE DATEDIFF(sn.nr_date, fc.first_date) > 1095
    SQL
  end

  def transform(query_results)
    query_results
      .group_by { |r| r["wca_id"] }
      .values
      .map do |rows|
        first = rows.first
        days = first["days"].to_i
        date_ord = first["nr_date"].respond_to?(:jd) ? first["nr_date"].jd : first["nr_date"].to_s.delete("-").to_i
        comps = rows.map { |r| r["comp_link"] }.uniq.join(", ")
        events = rows
          .map { |r| Events::ALL[r["event_id"]] || RETIRED_EVENTS[r["event_id"]] || r["event_id"] }
          .uniq
          .sort
          .join(", ")

        {
          days: days,
          date_ord: date_ord,
          person_name: first["person_name"].to_s,
          row: [first["person_link"], days, comps, events]
        }
      end
      .sort_by { |x| [-x[:days], x[:date_ord], x[:person_name]] }
      .map { |x| x[:row] }
  end
end

require "date"
require_relative "../core/grouped_statistic"
require_relative "../core/events"

class CumulativeDaysAsNr < GroupedStatistic
  CURRENT_EVENTS = %w[333 222 444 555 666 777 333bf 333fm 333oh clock minx pyram skewb sq1 444bf 555bf 333mbf].freeze

  def initialize
    @title = "Tiempo acumulado siendo Récord Nacional (NR)"
    @category = :records
    @note = "Días acumulados ostentando el Récord Nacional de España vigente en cada una de las 17 categorías actuales (Single y Average). En caso de empate exacto del NR, ambos competidores suman días; los récords actuales cuentan hasta hoy."
    @table_header = {
      "Días" => :right,
      "Años" => :right,
      "Persona" => :left,
      "¿Actual?" => :center
    }
  end

  def query
    event_list = CURRENT_EVENTS.map { |e| "'#{e}'" }.join(", ")
    <<-SQL
      SELECT
        r.event_id,
        r.person_id,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        r.best,
        r.average,
        r.regional_single_record,
        r.regional_average_record,
        c.start_date
      FROM results r
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1
      JOIN competitions c ON c.id = r.competition_id
      WHERE r.country_id = 'Spain'
        AND r.event_id IN (#{event_list})
        AND (
          (r.regional_single_record IS NOT NULL AND r.regional_single_record != '')
          OR (r.regional_average_record IS NOT NULL AND r.regional_average_record != '')
        )
    SQL
  end

  def parse_date(d)
    d.is_a?(Date) ? d : Date.parse(d.to_s)
  end

  def compute_days(records)
    return [] if records.empty?

    by_date = records.group_by { |r| r[:date] }
    current_best = nil
    current_holders = []
    last_date = nil
    days_by_person = Hash.new(0)
    links = {}

    by_date.keys.sort.each do |date|
      if last_date
        delta = (date - last_date).to_i
        current_holders.each { |pid| days_by_person[pid] += delta } if delta > 0
      end

      day_rows = by_date[date]
      day_rows.each { |r| links[r[:person_id]] = r[:person_link] }
      day_best = day_rows.map { |r| r[:mark] }.min

      if current_best.nil? || day_best < current_best
        current_best = day_best
        current_holders = day_rows.select { |r| r[:mark] == day_best }.map { |r| r[:person_id] }.uniq
      elsif day_best == current_best
        tied = day_rows.select { |r| r[:mark] == day_best }.map { |r| r[:person_id] }
        current_holders = (current_holders + tied).uniq
      end

      last_date = date
    end

    if last_date
      delta = [(Date.today - last_date).to_i, 0].max
      current_holders.each { |pid| days_by_person[pid] += delta }
    end

    days_by_person
      .select { |_, days| days > 0 }
      .sort_by { |pid, days| [-days, links[pid]] }
      .first(10)
      .map do |pid, days|
        [
          days,
          format("%.2f", days / 365.25),
          links[pid],
          current_holders.include?(pid) ? "Sí" : ""
        ]
      end
  end

  def transform(query_results)
    by_event = query_results.group_by { |r| r["event_id"] }
    groups = []

    CURRENT_EVENTS.each do |event_id|
      event_name = Events::ALL[event_id] || event_id
      event_rows = by_event[event_id] || []

      [
        [:single, "best", "regional_single_record", "Single"],
        [:average, "average", "regional_average_record", "Average"]
      ].each do |type, mark_col, rec_col, label|
        next if event_id == "333mbf" && type == :average

        records = event_rows.filter_map do |r|
          rec = r[rec_col]
          mark = r[mark_col].to_i
          next if rec.nil? || rec.empty? || mark <= 0

          {
            person_id: r["person_id"],
            person_link: r["person_link"],
            mark: mark,
            date: parse_date(r["start_date"])
          }
        end

        table = compute_days(records)
        groups << ["#{event_name} - #{label}", table] unless table.empty?
      end
    end

    groups
  end
end

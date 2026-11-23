require_relative "../core/statistic"

class FewestCompetitionsInCityAtFirstComp < Statistic
  def initialize
    @title = "Menor % de competiciones disputadas en la misma ciudad que la primera competición"
    @category = :competing
    @note = "Calcula qué porcentaje del total de competiciones de un competidor español (incluyendo el extranjero) tuvo lugar en la ciudad de su debut. Mínimo 10 competiciones."
    @table_header = {
      "Persona" => :left,
      "Primera competición" => :left,
      "Ciudad" => :left,
      "En la ciudad" => :right,
      "Total" => :right,
      "Porcentaje" => :right,
    }
  end

  def query
    <<-SQL
      SELECT
        p.name,
        p.wca_id,
        c.id AS competition_id,
        c.name AS competition_name,
        c.city_name,
        c.start_date
      FROM results r
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      JOIN competitions c ON c.id = r.competition_id
      WHERE c.results_posted_at IS NOT NULL
        AND c.cancelled_at IS NULL
      GROUP BY p.wca_id, c.id
    SQL
  end

  def transform(results)
    persons = {}
    results.each do |row|
      wca_id = row["wca_id"]
      persons[wca_id] ||= { name: row["name"], comps: [] }
      persons[wca_id][:comps] << {
        competition_id: row["competition_id"],
        competition_name: row["competition_name"],
        city: row["city_name"],
        start_date: row["start_date"],
      }
    end

    rows = persons.filter_map do |wca_id, data|
      first_comp = data[:comps].min_by { |c| c[:start_date] }
      city = first_comp[:city]

      total = data[:comps].size
      next if total < 10

      count = data[:comps].count { |c| c[:city] == city }
      ratio = count.to_f / total

      [
        "[#{data[:name]}](https://www.worldcubeassociation.org/persons/#{wca_id})",
        "[#{first_comp[:competition_name]}](https://www.worldcubeassociation.org/competitions/#{first_comp[:competition_id]})",
        city,
        count,
        total,
        "%.1f%%" % (ratio * 100),
        ratio,
      ]
    end

    rows
      .sort_by { |row| [row[6], row[3], row[0]] }
      .first(100)
      .map { |row| row[0..5] }
  end
end

require_relative "../core/statistic"
require_relative "../core/regions"

class FewestCompetitionsInCcaaAtFirstComp < Statistic
  include Regions::CCAA

  def initialize
    @title = "Menor % de competiciones disputadas en la comunidad autónoma de la primera competición"
    @category = :competing
    @note = "Comunidad o ciudad autónoma calculada a partir de las coordenadas de la competición (17 comunidades autónomas y 2 ciudades autónomas). Porcentaje de competiciones disputadas en la comunidad autónoma del debut respecto al total de competiciones (incluyendo extranjero). Mínimo 10 competiciones." \
            "The ratio is computed against all competitions attended, including those abroad. " \
            "Requires at least 10 total competitions."
    @table_header = {
      "Persona" => :left,
      "Primera competición" => :left,
      "Comunidad autónoma" => :left,
      "En la comunidad autónoma" => :right,
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
        c.start_date,
        IF(c.country_id = 'Spain' AND c.latitude IS NOT NULL AND c.longitude IS NOT NULL,
           c.latitude / 1000000.0, NULL) AS lat,
        IF(c.country_id = 'Spain' AND c.latitude IS NOT NULL AND c.longitude IS NOT NULL,
           c.longitude / 1000000.0, NULL) AS lon
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
        start_date: row["start_date"],
        lat: row["lat"],
        lon: row["lon"],
      }
    end

    rows = persons.filter_map do |wca_id, data|
      first_comp = data[:comps].min_by { |c| c[:start_date] }
      next unless first_comp[:lat] && first_comp[:lon]

      voiv = ccaa_for(first_comp[:lat], first_comp[:lon])
      next unless voiv

      total = data[:comps].size
      next if total < 10

      count = data[:comps].count { |c| c[:lat] && c[:lon] && ccaa_for(c[:lat], c[:lon]) == voiv }
      ratio = count.to_f / total

      [
        "[#{data[:name]}](https://www.worldcubeassociation.org/persons/#{wca_id})",
        "[#{first_comp[:competition_name]}](https://www.worldcubeassociation.org/competitions/#{first_comp[:competition_id]})",
        ccaa_display_name(voiv),
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

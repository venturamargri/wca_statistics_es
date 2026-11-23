require_relative "../core/statistic"
require_relative "../core/regions"

class ShortestTimeToCompeteInAllCcaaSincePossible < Statistic
  include Regions::CCAA

  def initialize
    @title = "Menor tiempo en competir en todas las comunidades autónomas desde que fue posible"
    @category = :milestones
    @note = "Comunidad o ciudad autónoma calculada a partir de las coordenadas de la competición (17 comunidades autónomas y 2 ciudades autónomas). El cronómetro empieza cuando todas las comunidades autónomas tuvieron al menos una competición a la que la persona pudo asistir (en o después de su debut)."
    @table_header = {
      "Persona" => :left,
      "Días" => :right,
      "Completado en" => :left,
      "Desbloqueado por" => :left
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
        c.end_date,
        c.latitude / 1000000.0 AS lat,
        c.longitude / 1000000.0 AS lon
      FROM results r
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      JOIN competitions c ON c.id = r.competition_id
      WHERE c.country_id = 'Spain'
      GROUP BY p.wca_id, c.id
    SQL
  end

  def transform(results)
    # Build per-voivodeship list of competitions sorted by start_date
    voiv_competitions = Hash.new { |h, k| h[k] = {} }
    results.each do |r|
      voiv = ccaa_for(r["lat"], r["lon"])
      next unless voiv
      comp_id = r["competition_id"]
      voiv_competitions[voiv][comp_id] ||= {
        start_date: r["start_date"],
        competition_id: comp_id,
        competition_name: r["competition_name"]
      }
    end

    return [] unless (ALL - voiv_competitions.keys).empty?

    voiv_sorted_comps = voiv_competitions.transform_values { |comps| comps.values.sort_by { |c| c[:start_date] } }

    # Build per-person data
    person_data = Hash.new { |h, k| h[k] = { name: "", regions: Set.new, history: [], first_comp: nil } }

    results.sort_by { |r| [r["wca_id"], r["end_date"]] }.each do |r|
      wca_id = r["wca_id"]
      voiv = ccaa_for(r["lat"], r["lon"])
      next unless voiv

      person_data[wca_id][:name] = r["name"]
      person_data[wca_id][:first_comp] ||= {
        start_date: r["start_date"],
        competition_id: r["competition_id"],
        competition_name: r["competition_name"]
      }

      unless person_data[wca_id][:regions].include?(voiv)
        person_data[wca_id][:history] << {
          voiv: voiv,
          competition_id: r["competition_id"],
          competition_name: r["competition_name"],
          start_date: r["start_date"],
          end_date: r["end_date"]
        }
      end

      person_data[wca_id][:regions] << voiv
    end

    person_data.filter_map do |wca_id, data|
      next unless (ALL - data[:regions].to_a).empty? && data[:history].any?

      first_start_date = data[:first_comp][:start_date]

      # For each voivodeship, find the first competition available to this person (on or after their debut)
      unlock = ALL.map { |voiv| voiv_sorted_comps[voiv].find { |c| c[:start_date] >= first_start_date } }
                  .compact
                  .max_by { |c| c[:start_date] }

      next unless unlock

      last = data[:history].max_by { |h| h[:end_date] }
      completion_comp = "[#{last[:competition_name]}](https://www.worldcubeassociation.org/competitions/#{last[:competition_id]})"
      enabled_by = "[#{unlock[:competition_name]}](https://www.worldcubeassociation.org/competitions/#{unlock[:competition_id]})"
      days = (last[:start_date] - unlock[:start_date]).to_i

      [
        "[#{data[:name]}](https://www.worldcubeassociation.org/persons/#{wca_id})",
        days,
        completion_comp,
        enabled_by
      ]
    end.sort_by { |row| [row[1], row[0]] }.first(100)
  end
end

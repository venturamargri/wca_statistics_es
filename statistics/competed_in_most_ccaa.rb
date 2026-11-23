require_relative "../core/statistic"
require_relative "../core/regions"

class CompetedInMostCcaa < Statistic
  include Regions::CCAA

  def initialize
    @title = "Más comunidades autónomas en las que se ha competido"
    @category = :travel
    @note = "Comunidad o ciudad autónoma calculada a partir de las coordenadas de la competición (17 comunidades autónomas y 2 ciudades autónomas)."
    @table_header = {
      "Persona" => :left,
      "Completadas" => :right,
      "Faltan" => :right,
      "Comunidades autónomas pendientes" => :left,
      "Completado en" => :left
    }
  end

  def query
    <<-SQL
      SELECT
        p.name,
        p.wca_id,
        c.id AS competition_id,
        c.name AS competition_name,
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
    person_competitions = Hash.new { |h, k| h[k] = { name: "", regions: Set.new, history: [] } }

    sorted_results = results.sort_by { |r| [r["wca_id"], r["end_date"]] }

    sorted_results.each do |r|
      name = r["name"]
      wca_id = r["wca_id"]
      lat = r["lat"]
      lon = r["lon"]
      competition_id = r["competition_id"]
      competition_name = r["competition_name"]
      end_date = r["end_date"]
      voiv = ccaa_for(lat, lon)
      next unless voiv

      unless person_competitions[wca_id][:regions].include?(voiv)
        person_competitions[wca_id][:history] << {
          voiv: voiv,
          competition_id: competition_id,
          competition_name: competition_name,
          end_date: end_date
        }
      end

      person_competitions[wca_id][:name] = name
      person_competitions[wca_id][:regions] << voiv
    end

    person_competitions.map do |wca_id, data|
      completed = data[:regions].to_a.sort
      missed = ALL - completed
      completion_info = nil
      completion_date = nil

      if missed.empty? && data[:history].any?
        last = data[:history].max_by { |h| h[:end_date] }
        completion_info = "[#{last[:competition_name]}](https://www.worldcubeassociation.org/competitions/#{last[:competition_id]})"
        completion_date = last[:end_date].to_s
      end

      person_link = "[#{data[:name]}](https://www.worldcubeassociation.org/persons/#{wca_id})"
      row = [person_link, completed.size, missed.size, missed.join(", "), completion_info]
      sort_key = [-completed.size, completion_date, missed.size, person_link]
      [sort_key, row]
    end.sort_by { |sort_key, _| sort_key }
       .map { |_, row| row }
       .first(100)
  end
end

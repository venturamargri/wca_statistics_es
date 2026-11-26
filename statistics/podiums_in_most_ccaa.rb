require "set"
require_relative "../core/statistic"
require_relative "../core/regions"

class PodiumsInMostCcaa < Statistic
  include Regions::CCAA

  def initialize
    @title = "Más comunidades autónomas distintas con podios"
    @category = :travel
    @note = "Competidores españoles que han conseguido al menos un podio oficial en más comunidades o ciudades autónomas distintas de España."
    @table_header = {
      "Persona" => :left,
      "Comunidades" => :right,
      "Comunidades autónomas" => :left
    }
  end

  def query
    <<-SQL
      SELECT DISTINCT
        p.name,
        p.wca_id,
        c.id AS competition_id,
        c.latitude / 1000000.0 AS lat,
        c.longitude / 1000000.0 AS lon
      FROM results r
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      JOIN competitions c ON c.id = r.competition_id
      WHERE c.country_id = 'Spain'
        AND r.round_type_id IN ('c', 'f')
        AND r.pos IN (1, 2, 3)
        AND r.best > 0
    SQL
  end

  def transform(query_results)
    by_person = Hash.new { |h, k| h[k] = { name: "", regions: Set.new } }

    query_results.each do |r|
      region = ccaa_for(r["lat"], r["lon"])
      next unless region

      rec = by_person[r["wca_id"]]
      rec[:name] = r["name"]
      rec[:regions] << region
    end

    by_person
      .map do |wca_id, data|
        regions = data[:regions].to_a.sort
        person_link = "[#{data[:name]}](https://www.worldcubeassociation.org/persons/#{wca_id})"
        [-regions.size, data[:name], [person_link, regions.size, regions.join(", ")]]
      end
      .sort_by { |neg_cnt, name, _| [neg_cnt, name] }
      .first(100)
      .map { |_, _, row| row }
  end
end

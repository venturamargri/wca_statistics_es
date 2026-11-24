require_relative "../core/statistic"

class MajorChampionshipFinalsByPerson < Statistic
  def initialize
    @title = "Número de finales en grandes campeonatos por persona"
    @category = :podiums
    @note = "Finales disputadas por competidores españoles en Campeonatos del Mundo, Campeonatos de Europa y Campeonatos de España (incluye todas las categorías históricas)."
    @table_header = {
      "Total" => :right,
      "Mundial" => :right,
      "Europeo" => :right,
      "Nacional" => :right,
      "Persona" => :left
    }
  end

  def query
    <<-SQL
      SELECT
        COUNT(DISTINCT CONCAT(r.competition_id, '|', r.event_id, '|', r.round_type_id)) AS total_finals,
        COUNT(DISTINCT CASE WHEN ch.championship_type = 'world' THEN CONCAT(r.competition_id, '|', r.event_id, '|', r.round_type_id) END) AS world_finals,
        COUNT(DISTINCT CASE WHEN ch.championship_type IN ('_Europe', 'Europe') THEN CONCAT(r.competition_id, '|', r.event_id, '|', r.round_type_id) END) AS euro_finals,
        COUNT(DISTINCT CASE WHEN ch.championship_type = 'ES' THEN CONCAT(r.competition_id, '|', r.event_id, '|', r.round_type_id) END) AS es_finals,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link
      FROM results r
      JOIN round_types rt ON rt.id = r.round_type_id AND rt.final = 1
      JOIN championships ch ON ch.competition_id = r.competition_id
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      WHERE ch.championship_type IN ('world', '_Europe', 'Europe', 'ES')
      GROUP BY p.wca_id, p.name
      ORDER BY total_finals DESC, world_finals DESC, euro_finals DESC, es_finals DESC, p.name ASC
      LIMIT 100
    SQL
  end
end

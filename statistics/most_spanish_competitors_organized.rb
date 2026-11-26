require_relative "../core/statistic"

class MostSpanishCompetitorsOrganized < Statistic
  def initialize
    @title = "Más competidores españoles distintos organizados"
    @category = :competitions
    @note = "Organizadores españoles de competiciones (en cualquier país) en las que ha participado el mayor número de competidores españoles distintos (excluyéndose a sí mismos)."
    @table_header = {
      "Persona" => :left,
      "Españoles distintos" => :right,
      "Competiciones" => :right
    }
  end

  def query
    <<-SQL
      WITH spanish_comp_attendance AS (
        SELECT DISTINCT
          r.competition_id,
          r.person_id
        FROM results r
        JOIN persons cp ON cp.wca_id = r.person_id AND cp.sub_id = 1 AND cp.country_id = 'Spain'
      ),
      spanish_role_holders AS (
        SELECT DISTINCT
          rt.competition_id,
          rp.wca_id,
          rp.name
        FROM competition_organizers rt
        JOIN users u ON u.id = rt.organizer_id
        JOIN persons rp ON rp.wca_id = u.wca_id AND rp.sub_id = 1 AND rp.country_id = 'Spain'
      )
      SELECT
        CONCAT('[', sr.name, '](https://www.worldcubeassociation.org/persons/', sr.wca_id, ')') AS person_link,
        COUNT(DISTINCT sca.person_id) AS spanish_competitors,
        COUNT(DISTINCT sr.competition_id) AS competitions_count
      FROM spanish_role_holders sr
      JOIN spanish_comp_attendance sca
        ON sca.competition_id = sr.competition_id
       AND sca.person_id != sr.wca_id
      GROUP BY sr.wca_id, sr.name
      ORDER BY spanish_competitors DESC, competitions_count DESC, sr.name ASC
      LIMIT 50
    SQL
  end

  def transform(query_results)
    query_results.map do |r|
      [
        r["person_link"],
        r["spanish_competitors"].to_i,
        r["competitions_count"].to_i
      ]
    end
  end
end

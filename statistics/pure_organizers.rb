require_relative "../core/statistic"

class PureOrganizers < Statistic
  def initialize
    @title = "Organizadores puros (sin competir)"
    @category = :competitions
    @note = "Competidores españoles que figuran como organizadores de competiciones ya celebradas en las que no registraron ningún resultado propio."
    @table_header = {
      "Sin competir" => :right,
      "Total organizadas" => :right,
      "Persona" => :left
    }
  end

  def query
    <<-SQL
      WITH spanish_org_comps AS (
        SELECT DISTINCT
          co.competition_id,
          p.wca_id,
          p.name,
          EXISTS (
            SELECT 1 FROM results r_self
            WHERE r_self.competition_id = co.competition_id
              AND r_self.person_id = p.wca_id
          ) AS competed
        FROM competition_organizers co
        JOIN users u ON u.id = co.organizer_id
        JOIN persons p ON p.wca_id = u.wca_id AND p.sub_id = 1 AND p.country_id = 'Spain'
        WHERE EXISTS (
          SELECT 1 FROM results r_any
          WHERE r_any.competition_id = co.competition_id
        )
      )
      SELECT
        SUM(CASE WHEN competed = 0 THEN 1 ELSE 0 END) AS pure_org_count,
        COUNT(*) AS total_org_count,
        CONCAT('[', name, '](https://www.worldcubeassociation.org/persons/', wca_id, ')') AS person_link
      FROM spanish_org_comps
      GROUP BY wca_id, name
      HAVING pure_org_count > 0
      ORDER BY pure_org_count DESC, total_org_count DESC, name ASC
      LIMIT 50
    SQL
  end
end

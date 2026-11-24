require_relative "../core/statistic"

class FemaleOrganizersAndDelegates < Statistic
  def initialize
    @title = "Participación femenina en organización y delegación"
    @category = :competing
    @note = "Mujeres que más competiciones oficiales celebradas en España han organizado o delegado. El total cuenta competiciones distintas (si ejerció ambos roles en el mismo torneo, cuenta una sola vez)."
    @table_header = {
      "Persona" => :left,
      "Organizadas" => :right,
      "Delegadas" => :right,
      "Total" => :right
    }
  end

  def query
    <<-SQL
      WITH spain_comps AS (
        SELECT c.id
        FROM competitions c
        WHERE c.country_id = 'Spain'
          AND EXISTS (SELECT 1 FROM results r WHERE r.competition_id = c.id)
      ),
      roles AS (
        SELECT
          co.competition_id,
          u.wca_id,
          1 AS is_org,
          0 AS is_del
        FROM competition_organizers co
        JOIN spain_comps sc ON sc.id = co.competition_id
        JOIN users u ON u.id = co.organizer_id
        WHERE u.wca_id IS NOT NULL AND u.wca_id != ''

        UNION ALL

        SELECT
          cd.competition_id,
          u.wca_id,
          0 AS is_org,
          1 AS is_del
        FROM competition_delegates cd
        JOIN spain_comps sc ON sc.id = cd.competition_id
        JOIN users u ON u.id = cd.delegate_id
        WHERE u.wca_id IS NOT NULL AND u.wca_id != ''
      )
      SELECT
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        COUNT(DISTINCT CASE WHEN ro.is_org = 1 THEN ro.competition_id END) AS organized,
        COUNT(DISTINCT CASE WHEN ro.is_del = 1 THEN ro.competition_id END) AS delegated,
        COUNT(DISTINCT ro.competition_id) AS total
      FROM roles ro
      JOIN persons p ON p.wca_id = ro.wca_id AND p.sub_id = 1
      WHERE p.gender = 'f'
      GROUP BY p.wca_id, p.name
      ORDER BY total DESC, delegated DESC, organized DESC, p.name ASC
    SQL
  end
end

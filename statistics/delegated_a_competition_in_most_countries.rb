require_relative "../core/statistic"

class DelegatedACompetitionInMostCountries < Statistic
  def initialize
    @title = "Delegado en más países"
    @category = :delegating
    @note = "Muestra los delegados españoles que han delegado en más países distintos (excluyendo competiciones FMC multisede)."
    @table_header = { "Nombre" => :left, "Países" => :right }
  end

  def query
    <<-SQL
      SELECT 
          CASE 
              WHEN d.wca_id IS NOT NULL THEN CONCAT('[', d.name, '](https://www.worldcubeassociation.org/persons/', d.wca_id, ')')
              ELSE d.name 
          END as delegate_name,
          COUNT(DISTINCT c.country_id) AS num_countries
      FROM 
          competition_delegates cd
      JOIN 
          competitions c ON cd.competition_id = c.id
      JOIN 
          users d ON cd.delegate_id = d.id AND d.country_iso2 = 'ES'
      WHERE
          c.country_id NOT IN ('XA', 'XE', 'XF', 'XM', 'XN', 'XO', 'XS', 'XW')
      GROUP BY 
          d.id, d.name, d.wca_id
      ORDER BY 
          num_countries DESC, d.name ASC;
    SQL
  end
end

require_relative "../core/statistic"

class DelegatedCompetitionPerYear < Statistic
  def initialize
    @title = "Competiciones delegadas por año"
    @category = :delegating
    @note = "Solo se incluyen delegados con al menos 3 competiciones delegadas."
    @table_header = { "Delegadas/año" => :right, "Delegadas" => :right, "Años" => :right, "Persona" => :left, "Lista en WCA" => :center }
  end

  def query
    <<-SQL
      SELECT
        (delegated_count / years) delegated_per_year,
        delegated_count,
        years,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link,
        CONCAT('[List](https://www.worldcubeassociation.org/competitions?year=all+years&state=past&delegate=', user.id, ')') list_link
      FROM (
        SELECT
          COUNT(DISTINCT competition_id) delegated_count,
          (DATEDIFF(MAX(end_date), MIN(start_date)) / 365.25) years,
          delegate_id
        FROM competition_delegates
        JOIN competitions competition ON competition.id = competition_id
        WHERE show_at_all = 1 AND cancelled_at IS NULL AND start_date < CURDATE()
        GROUP BY delegate_id
      ) AS delegated_count_by_user
      JOIN users user ON user.id = delegate_id
      JOIN persons person ON person.wca_id = user.wca_id AND person.sub_id = 1 AND person.country_id = 'Spain'
      WHERE delegated_count >= 3
      ORDER BY delegated_per_year DESC
    SQL
  end

  def transform(query_results)
    query_results.map do |result|
      ["%0.2f" % result["delegated_per_year"], result["delegated_count"], "%0.2f" % result["years"], result["person_link"], result["list_link"]]
    end
  end
end

require_relative "../core/statistic"

class MostFinals < Statistic
  def initialize
    @title = "Más finales disputadas"
    @category = :podiums
    @table_header = { "Finales" => :right, "Persona" => :left }
  end

  def query
    <<-SQL
      SELECT
        finals_count,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') person_link
      FROM (
        SELECT
          results.person_id wca_id,
          COUNT(*) finals_count
        FROM results
        JOIN round_types round_type ON round_type.id = results.round_type_id
        JOIN persons person ON person.wca_id = results.person_id AND person.sub_id = 1 AND person.country_id = 'Spain'
        WHERE round_type.final = 1
        GROUP BY results.person_id
        ORDER BY finals_count DESC
        LIMIT 100
      ) AS people_with_finals
      JOIN persons person ON person.wca_id = people_with_finals.wca_id AND person.sub_id = 1
      ORDER BY finals_count DESC
    SQL
  end
end

require_relative "../core/statistic"

class OhTo333 < Statistic
  def initialize
    @title = "Comparación de resultados de 3x3 One-Handed frente a 3x3 (España)"
    @category = :results
    @table_header = { "Persona" => :left, "3x3 OH" => :right, "3x3" => :right, "Proporción" => :right }
    @note = "Compara el mejor average oficial de 3x3x3 One-Handed con el de 3x3x3 en competidores españoles."
  end

  def query
    <<-SQL
      SELECT
          CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') person_link,
          a.best AS oh_best,
          b.best AS three_by_three_best,
          FORMAT(ROUND(a.best / b.best, 3), 2) AS ratio_oh_to_333
      FROM
          ranks_average a
      JOIN
          ranks_average b ON a.person_id = b.person_id
      JOIN persons p ON a.person_id = p.wca_id
      WHERE
          a.event_id = '333oh' AND b.event_id = '333' AND p.country_id = "Spain" AND p.sub_id = 1
      ORDER BY ROUND(a.best / b.best, 3)
      LIMIT 20;
    SQL
  end

  def transform(query_results)
    query_results.map do |result|
      oh_best = SolveTime.new("333oh", :average, result["oh_best"]).clock_format
      three_by_three_best = SolveTime.new("333", :average, result["three_by_three_best"]).clock_format
      [result["person_link"], oh_best, three_by_three_best, result["ratio_oh_to_333"]]
    end
  end
end

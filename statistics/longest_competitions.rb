require_relative "../core/statistic"

class LongestCompetitions < Statistic
  def initialize
    @title = "Competiciones más largas"
    @category = :competitions
    @table_header = { "Días" => :right, "Competición" => :left }
  end

  def query
    <<-SQL
      SELECT 
        (DATEDIFF(end_date, start_date) + 1) AS days,
        CONCAT('[', cell_name, '](https://www.worldcubeassociation.org/competitions/', id, ')') competition_link
      FROM competitions
      WHERE country_id = "Spain" AND results_posted_at IS NOT null
      HAVING days >= 3
      ORDER BY days desc;
    SQL
  end
end

require_relative "../core/statistic"

class NumberOfPeopleToReachMilestoneInCompsCount < Statistic
  def initialize
    @title = "Número de personas que alcanzaron hitos de competiciones"
    @category = :milestones
    @note = "Solo incluye competidores españoles."
    @table_header = { "Competiciones" => :left, "Personas" => :right }
  end

  def query
    <<-SQL
      WITH t AS (
        SELECT person_id AS id, COUNT(DISTINCT competition_id) AS comps FROM results WHERE results.country_id="Spain" GROUP BY person_id
      )
      SELECT '>= 1' AS Competitions, COUNT(id) AS Persons FROM t WHERE comps >= 1 UNION ALL
      SELECT '>= 50' AS Competitions, COUNT(id) AS Persons FROM t WHERE comps >= 50 UNION ALL
      SELECT '>= 100' AS Competitions, COUNT(id) AS Persons FROM t WHERE comps >= 100 UNION ALL
      SELECT '>= 150' AS Competitions, COUNT(id) AS Persons FROM t WHERE comps >= 150 UNION ALL
      SELECT '>= 200' AS Competitions, COUNT(id) AS Persons FROM t WHERE comps >= 200 UNION ALL
      SELECT '>= 250' AS Competitions, COUNT(id) AS Persons FROM t WHERE comps >= 250 UNION ALL
      SELECT '>= 300' AS Competitions, COUNT(id) AS Persons FROM t WHERE comps >= 300 UNION ALL
      SELECT '>= 350' AS Competitions, COUNT(id) AS Persons FROM t WHERE comps >= 350 UNION ALL
      SELECT '>= 400' AS Competitions, COUNT(id) AS Persons FROM t WHERE comps >= 400;
    SQL
  end
end

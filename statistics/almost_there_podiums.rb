require_relative "../core/grouped_statistic"

class AlmostTherePodiums < GroupedStatistic
  def initialize
    @title = "Eternos aspirantes (platas y bronces sin oro, y cuartos puestos sin podio)"
    @category = :podiums
    @note = "Competidores españoles con más medallas de plata o bronce sin haber ganado todavía ningún oro, y con más cuartos puestos en finales sin haber pisado nunca el podio."
    @table_header = {
      "Cantidad" => :right,
      "Persona" => :left,
      "Finales disputadas" => :right
    }
  end

  def query
    <<-SQL
      SELECT
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link,
        COUNT(*) AS finals_count,
        SUM(CASE WHEN r.pos = 1 AND r.best > 0 THEN 1 ELSE 0 END) AS golds,
        SUM(CASE WHEN r.pos = 2 AND r.best > 0 THEN 1 ELSE 0 END) AS silvers,
        SUM(CASE WHEN r.pos = 3 AND r.best > 0 THEN 1 ELSE 0 END) AS bronzes,
        SUM(CASE WHEN r.pos = 4 AND r.best > 0 THEN 1 ELSE 0 END) AS fourths
      FROM results r
      JOIN round_types rt ON rt.id = r.round_type_id AND rt.final = 1
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      GROUP BY p.wca_id, p.name
    SQL
  end

  def transform(query_results)
    silvers_no_gold = query_results
      .select { |r| r["golds"] == 0 && r["silvers"] > 0 }
      .sort_by { |r| [-r["silvers"], -r["finals_count"], r["person_link"]] }
      .first(30)
      .map { |r| [r["silvers"], r["person_link"], r["finals_count"]] }

    bronzes_no_gold = query_results
      .select { |r| r["golds"] == 0 && r["bronzes"] > 0 }
      .sort_by { |r| [-r["bronzes"], -r["finals_count"], r["person_link"]] }
      .first(30)
      .map { |r| [r["bronzes"], r["person_link"], r["finals_count"]] }

    fourths_no_podium = query_results
      .select { |r| r["golds"] == 0 && r["silvers"] == 0 && r["bronzes"] == 0 && r["fourths"] > 0 }
      .sort_by { |r| [-r["fourths"], -r["finals_count"], r["person_link"]] }
      .first(30)
      .map { |r| [r["fourths"], r["person_link"], r["finals_count"]] }

    [
      ["Más medallas de plata sin ningún oro", silvers_no_gold],
      ["Más medallas de bronce sin ningún oro", bronzes_no_gold],
      ["Más cuartos puestos sin ningún podio", fourths_no_podium]
    ]
  end
end

require_relative "../core/statistic"

class BestSpanishNurseryCompetitions < Statistic
  def initialize
    @title = "La mejor cantera de España"
    @category = :competitions
    @note = "Competiciones celebradas en España donde debutaron más competidores españoles que posteriormente lograron al menos un Récord Nacional (NR) o una medalla de oro oficial."
    @table_header = {
      "Futuros NRs" => :right,
      "Futuros oros" => :right,
      "Debutantes" => :right,
      "Competición" => :left,
      "Futuros poseedores de NR" => :left
    }
  end

  def query
    <<-SQL
      WITH spanish_persons AS (
        SELECT wca_id, name
        FROM persons
        WHERE sub_id = 1 AND country_id = 'Spain'
      ),
      person_comps AS (
        SELECT DISTINCT r.person_id, r.competition_id
        FROM results r
        JOIN spanish_persons sp ON sp.wca_id = r.person_id
      ),
      ranked_comps AS (
        SELECT
          pc.person_id,
          pc.competition_id,
          c.country_id,
          ROW_NUMBER() OVER (PARTITION BY pc.person_id ORDER BY c.start_date ASC, c.end_date ASC, c.id ASC) AS rn
        FROM person_comps pc
        JOIN competitions c ON c.id = pc.competition_id
      ),
      debuts_in_spain AS (
        SELECT person_id, competition_id
        FROM ranked_comps
        WHERE rn = 1 AND country_id = 'Spain'
      ),
      nr_holders AS (
        SELECT DISTINCT person_id
        FROM results
        WHERE country_id = 'Spain'
          AND (
            (regional_single_record IS NOT NULL AND regional_single_record != '')
            OR (regional_average_record IS NOT NULL AND regional_average_record != '')
          )
      ),
      gold_holders AS (
        SELECT DISTINCT r.person_id
        FROM results r
        JOIN round_types rt ON rt.id = r.round_type_id AND rt.final = 1
        JOIN spanish_persons sp ON sp.wca_id = r.person_id
        WHERE r.pos = 1 AND r.best > 0
      )
      SELECT
        c.id AS comp_id,
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, ')') AS comp_link,
        sp.name AS person_name,
        CONCAT('[', sp.name, '](https://www.worldcubeassociation.org/persons/', sp.wca_id, ')') AS person_link,
        CASE WHEN nh.person_id IS NOT NULL THEN 1 ELSE 0 END AS has_nr,
        CASE WHEN gh.person_id IS NOT NULL THEN 1 ELSE 0 END AS has_gold
      FROM debuts_in_spain d
      JOIN competitions c ON c.id = d.competition_id
      JOIN spanish_persons sp ON sp.wca_id = d.person_id
      LEFT JOIN nr_holders nh ON nh.person_id = d.person_id
      LEFT JOIN gold_holders gh ON gh.person_id = d.person_id
    SQL
  end

  def transform(query_results)
    query_results
      .group_by { |r| r["comp_id"] }
      .values
      .map do |rows|
        nrs = rows.select { |r| r["has_nr"].to_i == 1 }
        golds = rows.count { |r| r["has_gold"].to_i == 1 }
        nr_list = nrs.sort_by { |r| r["person_name"] }.map { |r| r["person_link"] }.join(", ")

        {
          nr_count: nrs.size,
          gold_count: golds,
          debutants: rows.size,
          comp_link: rows.first["comp_link"],
          nr_list: nr_list
        }
      end
      .select { |x| x[:nr_count] > 0 || x[:gold_count] > 0 }
      .sort_by { |x| [-x[:nr_count], -x[:gold_count], -x[:debutants], x[:comp_link]] }
      .first(50)
      .map { |x| [x[:nr_count], x[:gold_count], x[:debutants], x[:comp_link], x[:nr_list]] }
  end
end
# v2

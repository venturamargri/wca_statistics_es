require_relative "../core/statistic"

class BestSpanishNurseryCompetitions < Statistic
  def initialize
    @title = "Competiciones donde debutaron más personas con oros y récords nacionales"
    @category = :competitions
    @note = "Competiciones celebradas en España donde debutaron más competidores que posteriormente lograron al menos un Récord Nacional (NR) o una medalla de oro oficial. Si una persona logró tanto oro como NR, cuenta una sola vez en el total."
    @table_header = {
      "Total" => :right,
      "Futuros NRs" => :right,
      "Futuros oros" => :right,
      "Competición" => :left,
      "Personas" => :left
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
        nrs = rows.count { |r| r["has_nr"].to_i == 1 }
        golds = rows.count { |r| r["has_gold"].to_i == 1 }
        featured = rows.select { |r| r["has_nr"].to_i == 1 || r["has_gold"].to_i == 1 }
        people_list = featured.sort_by { |r| r["person_name"] }.map { |r| r["person_link"] }.join(", ")

        {
          total_count: featured.size,
          nr_count: nrs,
          gold_count: golds,
          comp_link: rows.first["comp_link"],
          people_list: people_list
        }
      end
      .select { |x| x[:total_count] > 0 }
      .sort_by { |x| [-x[:total_count], -x[:nr_count], -x[:gold_count], x[:comp_link]] }
      .first(50)
      .map { |x| [x[:total_count], x[:nr_count], x[:gold_count], x[:comp_link], x[:people_list]] }
  end
end

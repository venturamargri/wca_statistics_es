require_relative "../core/grouped_statistic"

class MostChampionshipsAttended < GroupedStatistic
  # Each category is a condition on the championship and on the country the
  # competitor represented. A category can break its count down into
  # BREAKDOWN_COLUMNS, and can show how many championships it has held so far.
  CATEGORIES = [
    {
      name: "Todos los campeonatos",
      condition: "TRUE",
      breakdown: ["world", "continental", "national"],
    },
    {
      # Championships whose title the competitor could win: World, their
      # continent's and their own country's. Not foreign nationals or other
      # continents' championships, which they could only compete at.
      name: "Todos los campeonatos elegibles",
      condition: "championship.championship_type IN ('world', country.continent_id, country.iso2)",
      breakdown: ["world", "own_continental", "own_national"],
    },
    {
      name: "Campeonatos del Mundo",
      condition: "championship.championship_type = 'world'",
      show_held: true,
    },
    {
      name: "Campeonatos de Europa",
      condition: "championship.championship_type = '_Europe'",
      show_held: true,
    },
    {
      name: "Campeonatos de España",
      condition: "championship.championship_type = 'ES'",
      show_held: true,
    },
    {
      name: "Campeonatos Nacionales de cualquier país",
      condition: "championship.championship_type IN (SELECT iso2 FROM countries WHERE iso2 IS NOT NULL)",
    },
  ]
  # Column label and the condition a championship must meet to count in it.
  BREAKDOWN_COLUMNS = {
    "world" => ["Mundial", "championship.championship_type = 'world'"],
    "continental" => ["Continental", "LEFT(championship.championship_type, 1) = '_'"],
    "national" => ["Nacional", "championship.championship_type IN (SELECT iso2 FROM countries WHERE iso2 IS NOT NULL)"],
    "own_continental" => ["Europeo", "championship.championship_type = country.continent_id"],
    "own_national" => ["España", "championship.championship_type = country.iso2"],
  }
  TOP_POSITIONS = 20

  def initialize
    @title = "Más campeonatos disputados"
    @category = :competing
    @note = "Solo incluye participaciones representando a España. Los campeonatos elegibles son Mundiales, Europeos y Campeonatos de España."
    @table_header = { "Posición" => :right, "Persona" => :left, "Campeonatos" => :right }
  end

  def query
    flags = BREAKDOWN_COLUMNS.map { |key, (_label, condition)| "(#{condition}) AS is_#{key}" }
    counts = BREAKDOWN_COLUMNS.keys.map { |key| "COUNT(DISTINCT IF(is_#{key}, competition_id, NULL)) AS #{key}_count" }

    attended = CATEGORIES.each_with_index.map do |category, index|
      <<-SQL
        SELECT DISTINCT
          #{index} AS category_index,
          result.person_id,
          championship.competition_id,
          #{flags.join(",\n")}
        FROM results result
        JOIN championships championship ON championship.competition_id = result.competition_id
        JOIN countries country ON country.id = result.country_id
        WHERE result.country_id = 'Spain'
          AND #{category[:condition]}
      SQL
    end

    # Conditions of categories that show the held count must not depend on the
    # competitor's country, as no competitor is involved here.
    held = CATEGORIES.each_with_index.select { |category, _index| category[:show_held] }.map do |category, index|
      <<-SQL
        SELECT #{index} AS category_index, COUNT(DISTINCT championship.competition_id) AS held_count
        FROM championships championship
        WHERE #{category[:condition]}
          AND EXISTS (SELECT 1 FROM results result WHERE result.competition_id = championship.competition_id)
      SQL
    end

    <<-SQL
      WITH attended AS (
        #{attended.join("UNION ALL\n")}
      ),
      held AS (
        #{held.join("UNION ALL\n")}
      ),
      ranked AS (
        SELECT
          category_index,
          person_id,
          COUNT(DISTINCT competition_id) AS championships_count,
          #{counts.join(",\n")},
          RANK() OVER (PARTITION BY category_index ORDER BY COUNT(DISTINCT competition_id) DESC) AS position
        FROM attended
        GROUP BY category_index, person_id
      )
      SELECT
        ranked.*,
        held.held_count,
        CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.wca_id, ')') AS person_link
      FROM ranked
      LEFT JOIN held ON held.category_index = ranked.category_index
      JOIN persons person ON person.wca_id = ranked.person_id AND person.sub_id = 1
      WHERE ranked.position <= #{TOP_POSITIONS}
      ORDER BY ranked.category_index, ranked.position, person.name
    SQL
  end

  def transform(query_results)
    query_results
      .group_by { |row| row["category_index"] }
      .map do |category_index, rows|
        category = CATEGORIES[category_index]
        breakdown = category.fetch(:breakdown, [])

        header = category[:name]
        header += "\n_Total de campeonatos: #{rows.first["held_count"]}_" if category[:show_held]

        table_header = @table_header.dup
        breakdown.each { |key| table_header[BREAKDOWN_COLUMNS[key].first] = :right }

        person_rows = rows.map do |row|
          [row["position"], row["person_link"], row["championships_count"]] +
            breakdown.map { |key| row["#{key}_count"] }
        end
        [header, person_rows, table_header]
      end
  end
end

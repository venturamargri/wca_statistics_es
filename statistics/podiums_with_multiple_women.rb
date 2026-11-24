require_relative "../core/statistic"
require_relative "../core/events"

class PodiumsWithMultipleWomen < Statistic
  def initialize
    @title = "Podios con múltiples mujeres"
    @category = :podiums
    @note = "Podios oficiales (en cualquier competición del mundo) en los que han coincidido dos o más competidoras españolas. Los podios con 3 mujeres aparecen arriba; dentro de cada grupo se ordenan cronológicamente (más antiguos primero)."
    @table_header = {
      "Competición" => :left,
      "Categoría" => :left,
      "Personas" => :left
    }
  end

  def query
    <<-SQL
      SELECT
        r.competition_id,
        r.event_id,
        r.round_type_id,
        r.pos,
        c.start_date,
        CONCAT('[', c.cell_name, '](https://www.worldcubeassociation.org/competitions/', c.id, '/results/all#e', r.event_id, '_', r.round_type_id, ')') AS comp_link,
        p.name AS person_name,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link
      FROM results r
      JOIN round_types rt ON rt.id = r.round_type_id AND rt.final = 1
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain' AND p.gender = 'f'
      JOIN competitions c ON c.id = r.competition_id
      WHERE r.pos IN (1, 2, 3)
        AND r.best > 0
    SQL
  end

  def transform(query_results)
    query_results
      .group_by { |r| [r["competition_id"], r["event_id"], r["round_type_id"]] }
      .values
      .select { |rows| rows.size >= 2 }
      .map do |rows|
        first = rows.first
        sorted_women = rows.sort_by { |r| [r["pos"].to_i, r["person_name"]] }
        people = sorted_women.map { |r| "#{r['pos']}.ª #{r['person_link']}" }.join(", ")
        event_name = Events::ALL[first["event_id"]] || first["event_id"]

        {
          count: rows.size,
          start_date: first["start_date"].to_s,
          comp_id: first["competition_id"],
          comp_link: first["comp_link"],
          event_name: event_name,
          people: people
        }
      end
      .sort_by { |x| [-x[:count], x[:start_date], x[:comp_id], x[:event_name]] }
      .map { |x| [x[:comp_link], x[:event_name], x[:people]] }
  end
end

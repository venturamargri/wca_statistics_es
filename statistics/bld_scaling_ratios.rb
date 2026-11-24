require_relative "../core/grouped_statistic"
require_relative "../core/solve_time"

class BldScalingRatios < GroupedStatistic
  PAIRS = [
    ["3x3x3 Blindfolded / 3x3x3", "333bf", "333"],
    ["4x4x4 Blindfolded / 3x3x3 Blindfolded", "444bf", "333bf"],
    ["5x5x5 Blindfolded / 4x4x4 Blindfolded", "555bf", "444bf"]
  ].freeze

  def initialize
    @title = "Escalado a ciegas (ratios en single)"
    @category = :results
    @note = "Menor ratio entre los singles oficiales (PB) de categorías a ciegas consecutivas (y 3BLD frente a 3x3). Es obligatorio tener single oficial en ambas categorías."
    @table_header = {
      "Ratio" => :right,
      "Persona" => :left,
      "Categoría superior (Single)" => :right,
      "Categoría base (Single)" => :right
    }
  end

  def query
    <<-SQL
      SELECT
        rs.event_id,
        rs.person_id,
        rs.best,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link
      FROM ranks_single rs
      JOIN persons p ON p.wca_id = rs.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      WHERE rs.event_id IN ('333', '333bf', '444bf', '555bf')
        AND rs.best > 0
    SQL
  end

  def transform(query_results)
    marks = Hash.new { |h, k| h[k] = {} }
    links = {}

    query_results.each do |r|
      pid = r["person_id"]
      marks[pid][r["event_id"]] = r["best"].to_i
      links[pid] = r["person_link"]
    end

    PAIRS.map do |label, top_id, base_id|
      rows = marks.filter_map do |pid, evs|
        top_val = evs[top_id]
        base_val = evs[base_id]
        next unless top_val && base_val && top_val > 0 && base_val > 0

        ratio = top_val.to_f / base_val.to_f
        {
          ratio: ratio,
          top_val: top_val,
          base_val: base_val,
          person_link: links[pid]
        }
      end
        .sort_by { |x| [x[:ratio], x[:top_val], x[:person_link]] }
        .first(20)
        .map do |x|
          [
            format("%.3f", x[:ratio]),
            x[:person_link],
            SolveTime.new(top_id, :single, x[:top_val]).clock_format,
            SolveTime.new(base_id, :single, x[:base_val]).clock_format
          ]
        end

      [label, rows]
    end
  end
end
# v2

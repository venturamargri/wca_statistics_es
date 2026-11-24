require_relative "../core/grouped_statistic"
require_relative "../core/solve_time"

class NxnRatios < GroupedStatistic
  PAIRS = [
    ["7x7x7 / 6x6x6", "777", "666", "7x7x7", "6x6x6"],
    ["6x6x6 / 5x5x5", "666", "555", "6x6x6", "5x5x5"],
    ["5x5x5 / 4x4x4", "555", "444", "5x5x5", "4x4x4"],
    ["4x4x4 / 3x3x3", "444", "333", "4x4x4", "3x3x3"],
    ["3x3x3 / 2x2x2", "333", "222", "3x3x3", "2x2x2"]
  ].freeze

  def initialize
    @title = "Comparación de NxNxN entre cubos consecutivos"
    @category = :results
    @note = "Menor proporción entre los averages oficiales (PB) de dos cubos NxNxN consecutivos. Es obligatorio tener average oficial en ambas categorías."
    @table_header = {
      "Persona" => :left,
      "__BIG__" => :right,
      "__SMALL__" => :right,
      "Proporción" => :right
    }
  end

  def query
    <<-SQL
      SELECT
        ra.event_id,
        ra.person_id,
        ra.best,
        CONCAT('[', p.name, '](https://www.worldcubeassociation.org/persons/', p.wca_id, ')') AS person_link
      FROM ranks_average ra
      JOIN persons p ON p.wca_id = ra.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
      WHERE ra.event_id IN ('222', '333', '444', '555', '666', '777')
        AND ra.best > 0
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

    @rendered_pairs = []

    PAIRS.filter_map do |label, big_id, small_id, big_col, small_col|
      rows = marks.filter_map do |pid, evs|
        big_val = evs[big_id]
        small_val = evs[small_id]
        next unless big_val && small_val && big_val > 0 && small_val > 0

        ratio = big_val.to_f / small_val.to_f
        {
          ratio: ratio,
          big_val: big_val,
          small_val: small_val,
          person_link: links[pid]
        }
      end
        .sort_by { |x| [x[:ratio], x[:big_val], x[:person_link]] }
        .first(20)
        .map do |x|
          [
            x[:person_link],
            SolveTime.new(big_id, :average, x[:big_val]).clock_format,
            SolveTime.new(small_id, :average, x[:small_val]).clock_format,
            format("%.3f", x[:ratio])
          ]
        end

      next if rows.empty?

      @rendered_pairs << [big_col, small_col]
      [label, rows]
    end
  end

  def markdown
    md = super
    (@rendered_pairs || []).each do |big_col, small_col|
      md = md.sub("__BIG__", big_col).sub("__SMALL__", small_col)
    end
    md
  end
end

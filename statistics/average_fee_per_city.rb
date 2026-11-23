require_relative "../core/grouped_statistic"

class AverageFeePerCity < GroupedStatistic
  def initialize
    @title = "Cuota media de inscripción por ciudad"
    @category = :competitions
    @note = "Solo se incluyen competiciones en EUR con al menos 2 ediciones en el mismo año."
    @table_header = { "Ciudad" => :left, "Cuota media" => :right, "Competiciones" => :right }
  end

  def query
    <<-SQL
      SELECT
        YEAR(start_date) AS year,
        city_name,
        base_entry_fee_lowest_denomination / 100.0 AS fee_eur
      FROM competitions
      WHERE country_id = 'Spain'
        AND currency_code = 'EUR'
        AND base_entry_fee_lowest_denomination IS NOT NULL
        AND results_posted_at IS NOT NULL
        AND cancelled_at IS NULL
    SQL
  end

  def transform(query_results)
    query_results
      .group_by { |row| row["year"] }
      .sort_by { |year, _| -year }
      .map do |year, rows|
        city_rows = rows
          .group_by { |row| row["city_name"] }
          .select { |_, city_comps| city_comps.size >= 2 }
          .map { |city, city_comps| [city, city_comps.sum { |row| row["fee_eur"].to_f } / city_comps.size, city_comps.size] }
          .sort_by { |city, avg_fee, _| [-avg_fee, city] }
          .map { |city, avg_fee, count| [city, "%.2f €" % avg_fee, count] }

        [year, city_rows]
      end
      .reject { |_, city_rows| city_rows.empty? }
  end
end

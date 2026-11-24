require_relative "../core/grouped_statistic"

class HighestRegistrationFee < GroupedStatistic
  def initialize
    @title = "Mayor cuota de inscripción en competiciones"
    @category = :competitions
    @note = "Solo se incluyen competiciones con cuota base en EUR."
    @table_header = { "Cuota" => :right, "Competición" => :left, "Fecha" => :left }
  end

  def query
    <<-SQL
      SELECT
        YEAR(start_date) AS year,
        CONCAT('[', cell_name, '](https://www.worldcubeassociation.org/competitions/', id, ')') AS competition_link,
        start_date,
        base_entry_fee_lowest_denomination / 100.0 AS fee_eur
      FROM competitions
      WHERE country_id = 'Spain'
        AND currency_code = 'EUR'
        AND base_entry_fee_lowest_denomination IS NOT NULL
        AND results_posted_at IS NOT NULL
        AND cancelled_at IS NULL
      ORDER BY year DESC, base_entry_fee_lowest_denomination DESC, start_date ASC
    SQL
  end

  def transform(query_results)
    query_results
      .group_by { |row| row["year"] }
      .map do |year, rows|
        comp_rows = rows.first(10).map do |row|
          ["%.2f €" % row["fee_eur"], row["competition_link"], row["start_date"]]
        end
        [year, comp_rows]
      end
  end
end

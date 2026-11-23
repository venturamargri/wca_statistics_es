require_relative "../core/grouped_statistic"
require_relative "../core/regions"

class AverageFeePerProvince < GroupedStatistic
  include Regions::Provinces

  def initialize
    @title = "Cuota media de inscripción por provincia"
    @category = :competitions
    @note = "Provincia o ciudad autónoma calculada a partir de las coordenadas de la competición (50 provincias y 2 ciudades autónomas). Solo se incluyen competiciones en EUR."
    @table_header = { "Provincia" => :left, "Cuota media" => :right, "Competiciones" => :right }
  end

  def query
    <<-SQL
      SELECT
        YEAR(start_date) AS year,
        base_entry_fee_lowest_denomination / 100.0 AS fee_eur,
        latitude / 1000000.0 AS lat,
        longitude / 1000000.0 AS lon
      FROM competitions
      WHERE country_id = 'Spain'
        AND currency_code = 'EUR'
        AND base_entry_fee_lowest_denomination IS NOT NULL
        AND results_posted_at IS NOT NULL
        AND cancelled_at IS NULL
        AND latitude IS NOT NULL
        AND longitude IS NOT NULL
    SQL
  end

  def transform(query_results)
    query_results
      .group_by { |row| row["year"] }
      .sort_by { |year, _| -year }
      .map do |year, rows|
        by_voivodeship = Hash.new { |h, k| h[k] = [] }
        rows.each do |row|
          voiv = province_for(row["lat"].to_f, row["lon"].to_f)
          by_voivodeship[voiv] << row["fee_eur"].to_f if voiv
        end

        voivodeship_rows = by_voivodeship
          .map { |voiv, fees| [province_display_name(voiv), fees.sum / fees.size, fees.size] }
          .sort_by { |_, avg_fee, _| -avg_fee }
          .map { |name, avg_fee, count| [name, "%.2f €" % avg_fee, count] }

        [year, voivodeship_rows]
      end
  end

end

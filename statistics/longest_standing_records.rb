require_relative "abstract/national_record_periods"

class LongestStandingRecords < NationalRecordPeriods
  def initialize
    @title = "Récords nacionales más longevos"
    @category = :records
    @note = "Récords nacionales de España (incluidos ER y WR batidos por españoles) ordenados por su duración. Los récords vigentes cuentan hasta hoy."
    @table_header = { "Persona" => :left, "Categoría" => :left, "Tipo" => :left, "Resultado" => :right, "Inicio" => :left, "Fin" => :left, "Días" => :right, "Competición" => :left }
  end

  def transform(query_results)
    records(query_results)
      .map { |record| record.merge(end_date: record[:beaten_by]&.fetch(:start_date)) }
      .sort_by { |record| -days(record[:start_date], record[:end_date]) }
      .take(50)
      .map do |record|
        [
          record[:person_link],
          record[:event],
          record[:type],
          record[:result],
          format_date(record[:start_date]),
          format_date(record[:end_date]),
          "**#{days(record[:start_date], record[:end_date])}**",
          record[:results_link]
        ]
      end
  end
end

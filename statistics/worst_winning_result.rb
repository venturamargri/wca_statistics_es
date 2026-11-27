require_relative "./abstract/worst_qualifying_results"

class WorstWinningResult < WorstQualifyingResults
  def initialize
    super(
      title: "Peor resultado que logró victoria",
      note: "Solo finales de competidores españoles en competiciones celebradas en España. Se ignoran resultados donde la métrica principal sea DNF.",
      max_position: 1,
      joins: <<-SQL,
        JOIN persons person ON person.wca_id = results.person_id AND person.sub_id = 1 AND person.country_id = 'Spain'
      SQL
      condition: "AND competition.country_id = 'Spain'"
    )
  end
end

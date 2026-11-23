require_relative "./abstract/worst_qualifying_results"

class YearlyWorstWinningResult < WorstQualifyingResults
  def initialize
    super(
      title: "Peor resultado que logró victoria por año en competiciones en España",
      note: "Solo finales en competiciones celebradas en España, independientemente de la nacionalidad del ganador. Se ignoran resultados donde la métrica principal sea DNF.",
      max_position: 1,
      condition: "AND competition.country_id = 'Spain'",
      yearly: true
    )
  end
end

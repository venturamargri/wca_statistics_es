require_relative "./abstract/worst_qualifying_results"

class YearlyWorstResultOnPodium < WorstQualifyingResults
  def initialize
    super(
      title: "Peor resultado que logró podio por año en competiciones en España",
      note: "Solo finales en competiciones celebradas en España, independientemente de la nacionalidad del medallista. Se ignoran resultados donde la métrica principal sea DNF.",
      max_position: 3,
      condition: "AND competition.country_id = 'Spain'",
      yearly: true
    )
  end
end
# v2

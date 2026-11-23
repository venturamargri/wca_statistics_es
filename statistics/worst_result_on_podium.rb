require_relative "./abstract/worst_qualifying_results"

class WorstResultOnPodium < WorstQualifyingResults
  def initialize
    super(
      title: "Peor resultado que logró podio",
      note: "Solo se tienen en cuenta finales. Se ignoran resultados donde la métrica principal sea DNF.",
      max_position: 3,
      joins: <<-SQL
        JOIN persons person ON person.wca_id = results.person_id AND person.sub_id = 1 AND person.country_id = 'Spain'
      SQL
    )
  end
end

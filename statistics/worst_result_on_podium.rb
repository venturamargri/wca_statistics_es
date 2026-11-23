require_relative "./abstract/worst_qualifying_results"

class WorstResultOnPodium < WorstQualifyingResults
  def initialize
    super(
      title: "Worst result providing a podium",
      note: "Only finals are taken into account. Results where the main statistic is DNF are ignored.",
      max_position: 3,
      joins: <<-SQL
        JOIN persons person ON person.wca_id = results.person_id AND person.sub_id = 1 AND person.country_id = 'Spain'
      SQL
    )
  end
end

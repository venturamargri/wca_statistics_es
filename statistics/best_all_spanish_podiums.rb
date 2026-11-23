require_relative "./abstract/best_podiums"

class BestAllSpanishPodiums < BestPodiums
  def initialize
    super(
      title: "Mejores podios íntegramente españoles",
      note: "Podios en cualquier competición donde los tres medallistas representaban a España, ordenados por la suma de sus resultados de clasificación.",
      condition: <<-SQL
        AND results.country_id = 'Spain'
        AND NOT EXISTS (
          SELECT 1 FROM results r3
          WHERE r3.competition_id = results.competition_id
            AND r3.event_id = results.event_id
            AND r3.round_type_id = results.round_type_id
            AND r3.pos IN (1, 2, 3)
            AND r3.best > 0
            AND r3.country_id != 'Spain'
        )
      SQL
    )
  end
end

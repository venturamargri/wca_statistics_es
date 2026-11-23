require_relative "./abstract/rankings"

class YearlyRankings < Rankings
  def initialize
    super(
      title: "Rankings anuales",
      note: "Incluye únicamente resultados del año en curso.",
      condition: <<-SQL
        WHERE YEAR(competition.start_date) = YEAR(CURDATE())
      SQL
    )
  end
end
# v2

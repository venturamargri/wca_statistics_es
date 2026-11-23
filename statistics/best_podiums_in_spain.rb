require_relative "./abstract/best_podiums"

class BestPodiumsInSpain < BestPodiums
  def initialize
    super(
      title: "Mejores podios en competiciones en España",
      note: "Podios en competiciones celebradas en España, independientemente de la nacionalidad de los medallistas.",
      condition: <<-SQL
        AND competition.country_id = 'Spain'
      SQL
    )
  end
end
# v2

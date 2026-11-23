require_relative "abstract/places_with_most_competitions_by_year"
require_relative "../core/regions"

class CcaaWithMostCompetitionsByYear < PlacesWithMostCompetitionsByYear
  include Regions::CCAA

  def initialize
    super(place: "Comunidad autónoma", places: "Comunidades autónomas", note: "Comunidad o ciudad autónoma calculada a partir de las coordenadas de la competición (17 comunidades autónomas y 2 ciudades autónomas).")
  end

  def place_for(row)
    ccaa_display_name(ccaa_for(row["lat"].to_f, row["lon"].to_f))
  end
end

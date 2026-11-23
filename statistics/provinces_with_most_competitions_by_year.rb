require_relative "abstract/places_with_most_competitions_by_year"
require_relative "../core/regions"

class ProvincesWithMostCompetitionsByYear < PlacesWithMostCompetitionsByYear
  include Regions::Provinces

  def initialize
    super(place: "Provincia", places: "Provincias", note: "Provincia o ciudad autónoma calculada a partir de las coordenadas de la competición (50 provincias y 2 ciudades autónomas).")
  end

  def place_for(row)
    province_display_name(province_for(row["lat"].to_f, row["lon"].to_f))
  end
end

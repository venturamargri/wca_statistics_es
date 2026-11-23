require_relative "abstract/places_with_most_competitions_by_year"

class CitiesWithMostCompetitionsByYear < PlacesWithMostCompetitionsByYear
  def initialize
    super(place: "Ciudad", places: "Ciudades", note: "Se muestran las 20 ciudades con más competiciones cada año.")
  end

  def place_for(row)
    row["city_name"]
  end
end

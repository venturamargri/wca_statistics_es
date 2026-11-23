require "json"

module Regions
  # Respaldo de las 52 provincias/ciudades autónomas con sus coordenadas centrales y CCAA asociada
  PROVINCES_FALLBACK = [
    ["Álava", "País Vasco", 42.8467, -2.6716],
    ["Albacete", "Castilla-La Mancha", 38.9943, -1.8585],
    ["Alicante", "Comunitat Valenciana", 38.3452, -0.4810],
    ["Almería", "Andalucía", 36.8340, -2.4637],
    ["Asturias", "Principado de Asturias", 43.3614, -5.8593],
    ["Ávila", "Castilla y León", 40.6566, -4.6812],
    ["Badajoz", "Extremadura", 38.8794, -6.9707],
    ["Illes Balears", "Illes Balears", 39.5696, 2.6502],
    ["Barcelona", "Cataluña", 41.3851, 2.1734],
    ["Burgos", "Castilla y León", 42.3439, -3.6969],
    ["Cáceres", "Extremadura", 39.4753, -6.3724],
    ["Cádiz", "Andalucía", 36.5271, -6.2886],
    ["Cantabria", "Cantabria", 43.4623, -3.8099],
    ["Castellón", "Comunitat Valenciana", 39.9864, -0.0513],
    ["Ceuta", "Ceuta", 35.8894, -5.3213],
    ["Ciudad Real", "Castilla-La Mancha", 38.9848, -3.9274],
    ["Córdoba", "Andalucía", 37.8882, -4.7794],
    ["A Coruña", "Galicia", 43.3623, -8.4115],
    ["Cuenca", "Castilla-La Mancha", 40.0704, -2.1374],
    ["Girona", "Cataluña", 41.9794, 2.8214],
    ["Granada", "Andalucía", 37.1773, -3.5986],
    ["Guadalajara", "Castilla-La Mancha", 40.6337, -3.1674],
    ["Gipuzkoa", "País Vasco", 43.3183, -1.9812],
    ["Huelva", "Andalucía", 37.2614, -6.9447],
    ["Huesca", "Aragón", 42.1401, -0.4089],
    ["Jaén", "Andalucía", 37.7796, -3.7849],
    ["León", "Castilla y León", 42.5987, -5.5671],
    ["Lleida", "Cataluña", 41.6176, 0.6200],
    ["Lugo", "Galicia", 43.0097, -7.5567],
    ["Madrid", "Comunidad de Madrid", 40.4168, -3.7038],
    ["Málaga", "Andalucía", 36.7213, -4.4214],
    ["Melilla", "Melilla", 35.2923, -2.9381],
    ["Murcia", "Región de Murcia", 37.9922, -1.1307],
    ["Navarra", "Comunidad Foral de Navarra", 42.8125, -1.6458],
    ["Ourense", "Galicia", 42.3358, -7.8639],
    ["Palencia", "Castilla y León", 42.0095, -4.5288],
    ["Las Palmas", "Canarias", 28.1235, -15.4363],
    ["Pontevedra", "Galicia", 42.4310, -8.6444],
    ["La Rioja", "La Rioja", 42.4627, -2.4450],
    ["Salamanca", "Castilla y León", 40.9701, -5.6635],
    ["Santa Cruz de Tenerife", "Canarias", 28.4636, -16.2518],
    ["Segovia", "Castilla y León", 40.9429, -4.1088],
    ["Sevilla", "Andalucía", 37.3891, -5.9845],
    ["Soria", "Castilla y León", 41.7665, -2.4790],
    ["Tarragona", "Cataluña", 41.1189, 1.2445],
    ["Teruel", "Aragón", 40.3456, -1.1065],
    ["Toledo", "Castilla-La Mancha", 39.8628, -4.0273],
    ["Valencia", "Comunitat Valenciana", 39.4699, -0.3763],
    ["Valladolid", "Castilla y León", 41.6523, -4.7245],
    ["Bizkaia", "País Vasco", 43.2630, -2.9350],
    ["Zamora", "Castilla y León", 41.5035, -5.7467],
    ["Zaragoza", "Aragón", 41.6488, -0.8891],
  ].freeze

  NAME_NORMALIZATION = {
    "andalucia" => "Andalucía",
    "aragon" => "Aragón",
    "asturias" => "Principado de Asturias",
    "principado de asturias" => "Principado de Asturias",
    "baleares" => "Illes Balears",
    "illes balears" => "Illes Balears",
    "islas baleares" => "Illes Balears",
    "canarias" => "Canarias",
    "islas canarias" => "Canarias",
    "cantabria" => "Cantabria",
    "castilla-la mancha" => "Castilla-La Mancha",
    "castilla la mancha" => "Castilla-La Mancha",
    "castilla y leon" => "Castilla y León",
    "castilla-leon" => "Castilla y León",
    "cataluna" => "Cataluña",
    "catalunya" => "Cataluña",
    "comunidad valenciana" => "Comunitat Valenciana",
    "comunitat valenciana" => "Comunitat Valenciana",
    "valencia" => "Valencia",
    "extremadura" => "Extremadura",
    "galicia" => "Galicia",
    "madrid" => "Madrid",
    "comunidad de madrid" => "Comunidad de Madrid",
    "murcia" => "Murcia",
    "region de murcia" => "Región de Murcia",
    "navarra" => "Navarra",
    "comunidad foral de navarra" => "Comunidad Foral de Navarra",
    "pais vasco" => "País Vasco",
    "euskadi" => "País Vasco",
    "la rioja" => "La Rioja",
    "rioja, la" => "La Rioja",
    "ceuta" => "Ceuta",
    "melilla" => "Melilla",
    "alava" => "Álava",
    "araba" => "Álava",
    "araba/alava" => "Álava",
    "alava/araba" => "Álava",
    "alicante" => "Alicante",
    "alacant" => "Alicante",
    "alicante/alacant" => "Alicante",
    "almeria" => "Almería",
    "avila" => "Ávila",
    "caceres" => "Cáceres",
    "cadiz" => "Cádiz",
    "castellon" => "Castellón",
    "castello" => "Castellón",
    "castellon/castello" => "Castellón",
    "cordoba" => "Córdoba",
    "a coruna" => "A Coruña",
    "la coruna" => "A Coruña",
    "coruna, a" => "A Coruña",
    "girona" => "Girona",
    "gerona" => "Girona",
    "gipuzkoa" => "Gipuzkoa",
    "guipuzcoa" => "Gipuzkoa",
    "jaen" => "Jaén",
    "leon" => "León",
    "lleida" => "Lleida",
    "lerida" => "Lleida",
    "malaga" => "Málaga",
    "orense" => "Ourense",
    "ourense" => "Ourense",
    "palmas, las" => "Las Palmas",
    "las palmas" => "Las Palmas",
    "santa cruz de tenerife" => "Santa Cruz de Tenerife",
    "valencia/valencia" => "Valencia",
    "bizkaia" => "Bizkaia",
    "vizcaya" => "Bizkaia",
  }.freeze

  def self.normalize_name(raw, is_ccaa: false)
    return nil if raw.nil?
    cleaned = raw.to_s.strip
    ascii_key = cleaned.downcase
      .tr("áéíóúüñàèìòù", "aeiouunaeiou")
    if is_ccaa
      return "Comunidad de Madrid" if ascii_key == "madrid"
      return "Región de Murcia" if ascii_key == "murcia"
      return "Comunidad Foral de Navarra" if ascii_key == "navarra"
      return "Comunitat Valenciana" if ascii_key == "valencia"
    end
    NAME_NORMALIZATION[ascii_key] || cleaned
  end

  def self.extract_feature_name(props, is_ccaa: false)
    return nil unless props.is_a?(Hash)
    candidates = %w[name NAME_2 NAME_1 texto rotuloacom rotulo prov_name acom_name provincia comunidad NAME]
    raw = candidates.map { |k| props[k] }.compact.find { |v| !v.to_s.strip.empty? }
    normalize_name(raw, is_ccaa: is_ccaa)
  end

  def self.load_polygons(relative_path, is_ccaa: false)
    full_path = File.expand_path(relative_path, __dir__)
    return {} unless File.exist?(full_path)

    features = JSON.parse(File.read(full_path))["features"] || []
    features.each_with_object(Hash.new { |h, k| h[k] = [] }) do |feature, hash|
      name = extract_feature_name(feature["properties"], is_ccaa: is_ccaa)
      next unless name

      geom = feature["geometry"] || {}
      polys = case geom["type"]
              when "Polygon" then [geom["coordinates"]]
              when "MultiPolygon" then geom["coordinates"]
              else []
              end
      hash[name].concat(polys)
    end.freeze
  end

  def self.lookup_in_polygons(polygons, lat, lon)
    return nil if lat.nil? || lon.nil?
    x = lon.to_f
    y = lat.to_f

    polygons.each do |name, poly_list|
      poly_list.each do |rings|
        next if rings.nil? || rings.empty?
        exterior = rings[0]
        holes = rings[1..] || []
        if point_in_ring?(x, y, exterior) && holes.none? { |h| point_in_ring?(x, y, h) }
          return name
        end
      end
    end

    # Tolerancia costera: si el pin cae ligeramente en el mar (< ~30 km), asigna la región más cercana
    best_name = nil
    best_dist_sq = 0.09 # (0.3 grados)^2
    polygons.each do |name, poly_list|
      poly_list.each do |rings|
        next if rings.nil? || rings.empty?
        rings[0].each do |px, py|
          d_sq = (px - x) ** 2 + (py - y) ** 2
          if d_sq < best_dist_sq
            best_dist_sq = d_sq
            best_name = name
          end
        end
      end
    end
    best_name
  end

  def self.point_in_ring?(x, y, ring)
    inside = false
    j = ring.length - 1
    ring.length.times do |i|
      xi, yi = ring[i]
      xj, yj = ring[j]
      if ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
        inside = !inside
      end
      j = i
    end
    inside
  end

  def self.fallback_province_row(lat, lon)
    return nil if lat.nil? || lon.nil?
    y = lat.to_f
    x = lon.to_f
    PROVINCES_FALLBACK.min_by { |_, _, plat, plon| (plat - y) ** 2 + (plon - x) ** 2 }
  end

  module CCAA
    POLYGONS = Regions.load_polygons("data/ccaa.geojson", is_ccaa: true)
    ALL = (POLYGONS.empty? ? Regions::PROVINCES_FALLBACK.map { |r| r[1] }.uniq : POLYGONS.keys).sort.freeze

    def ccaa_for(lat, lon)
      return nil if lat.nil? || lon.nil?
      unless POLYGONS.empty?
        found = Regions.lookup_in_polygons(POLYGONS, lat, lon)
        return found if found
      end
      Regions.fallback_province_row(lat, lon)&.[](1)
    end

    def ccaa_display_name(name)
      name.to_s
    end
  end

  module Provinces
    POLYGONS = Regions.load_polygons("data/provinces.geojson", is_ccaa: false)
    ALL = (POLYGONS.empty? ? Regions::PROVINCES_FALLBACK.map { |r| r[0] }.uniq : POLYGONS.keys).sort.freeze

    def province_for(lat, lon)
      return nil if lat.nil? || lon.nil?
      unless POLYGONS.empty?
        found = Regions.lookup_in_polygons(POLYGONS, lat, lon)
        return found if found
      end
      Regions.fallback_province_row(lat, lon)&.[](0)
    end

    def province_display_name(name)
      name.to_s
    end
  end
end

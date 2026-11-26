require_relative "../core/statistic"

class LargestSpanishCompetitorNetwork < Statistic
  HEX_POPCOUNT = {
    "0" => 0, "1" => 1, "2" => 1, "3" => 2,
    "4" => 1, "5" => 2, "6" => 2, "7" => 3,
    "8" => 1, "9" => 2, "a" => 2, "b" => 3,
    "c" => 2, "d" => 3, "e" => 3, "f" => 4
  }.freeze

  def initialize
    @title = "Mayor red de competidores españoles distintos"
    @category = :competitions
    @note = "Competidores españoles que han coincidido en competición (en cualquier país) con el mayor número de otros competidores españoles distintos, junto al porcentaje sobre el censo histórico español."
    @table_header = {
      "Persona" => :left,
      "Españoles distintos" => :right,
      "% del histórico" => :right
    }
  end

  def query
    <<-SQL
      SELECT DISTINCT
        r.competition_id,
        p.wca_id,
        p.name
      FROM results r
      JOIN persons p ON p.wca_id = r.person_id AND p.sub_id = 1 AND p.country_id = 'Spain'
    SQL
  end

  def transform(query_results)
    wca_to_idx = {}
    idx_to_wca = []
    idx_to_name = []
    comp_masks = Hash.new(0)
    person_comps = []

    query_results.each do |r|
      wca_id = r["wca_id"]
      idx = wca_to_idx[wca_id]
      unless idx
        idx = idx_to_wca.size
        wca_to_idx[wca_id] = idx
        idx_to_wca << wca_id
        idx_to_name << r["name"]
        person_comps << []
      end

      cid = r["competition_id"]
      comp_masks[cid] |= (1 << idx)
      person_comps[idx] << cid
    end

    total_spanish = idx_to_wca.size
    denom = total_spanish - 1
    return [] if denom <= 0

    rows = []
    total_spanish.times do |idx|
      mask = 0
      person_comps[idx].each { |cid| mask |= comp_masks[cid] }
      mask &= ~(1 << idx)

      met = mask.to_s(16).each_char.sum { |ch| HEX_POPCOUNT[ch] }
      next if met == 0

      pct = format("%.2f%%", (met * 100.0) / denom)
      name = idx_to_name[idx]
      link = "[#{name}](https://www.worldcubeassociation.org/persons/#{idx_to_wca[idx]})"
      rows << [met, name, [link, met, pct]]
    end

    rows
      .sort_by { |met, name, _| [-met, name] }
      .first(50)
      .map { |_, _, row| row }
  end
end

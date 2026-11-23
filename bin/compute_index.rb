#!/usr/bin/env ruby

require_relative "../core/categories"
require_relative "../core/spanish_format"
require_relative "../statistics/index"

puts "Generando índice de estadísticas."
build_path = File.expand_path("../build", __dir__)

uncategorized = STATISTICS.reject { |statistic_id, statistic_object| CATEGORIES.key?(statistic_object.category) }
unless uncategorized.empty?
  abort "Estadísticas sin categoría o con categoría desconocida: #{uncategorized.keys.join(', ')}. Usa una de: #{CATEGORIES.keys.join(', ')}."
end

statistics_by_category = STATISTICS.group_by { |statistic_id, statistic_object| statistic_object.category }

anchor = ->(category) { category.to_s.tr("_", "-") }

contents = CATEGORIES
  .map { |category, name| "[#{name}](##{anchor[category]}) (#{statistics_by_category.fetch(category, []).size})" }
  .join(" · ")

sections = CATEGORIES.map do |category, name|
  list = statistics_by_category.fetch(category, [])
    .sort_by { |statistics_id, statistic_object| statistic_object.title.gsub(/\d+/) { |number| number.rjust(10, "0") } }
    .map { |statistics_id, statistic_object| "- [#{statistic_object.title}](#{statistics_id})\n" }
    .join
  "## #{name} {##{anchor[category]}}\n\n#{list}"
end

destination_path = File.join(build_path, "README.md")
intro = "Todas las estadísticas están calculadas únicamente para competidores que representan a España o competiciones celebradas en España.\n\n"
footer = "\n\nEsta información se basa en los resultados oficiales publicados por la World Cube Association en [https://worldcubeassociation.org](https://worldcubeassociation.org) a fecha de #{SpanishFormat.full_date(Time.now)}."
File.write(destination_path, intro + contents + "\n\n" + sections.join("\n") + footer)
puts "Índice generado en #{destination_path}"

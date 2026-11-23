module SpanishFormat
  MONTHS_FULL = [
    nil,
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
  ].freeze

  MONTHS_SHORT = [
    nil,
    "ene", "feb", "mar", "abr", "may", "jun",
    "jul", "ago", "sep", "oct", "nov", "dic"
  ].freeze

  def self.short_date(date)
    return nil unless date
    "#{date.day}&nbsp;#{MONTHS_SHORT[date.month]}&nbsp;#{date.year}"
  end

  def self.plain_short_date(date)
    return nil unless date
    "#{date.day} #{MONTHS_SHORT[date.month]} #{date.year}"
  end

  def self.full_date(date)
    return nil unless date
    "#{date.day} de #{MONTHS_FULL[date.month].downcase} de #{date.year}"
  end

  def self.day_month(date)
    return nil unless date
    "#{date.day} de #{MONTHS_FULL[date.month].downcase}"
  end

  def self.month_name(month_num)
    MONTHS_FULL[month_num]
  end

  def self.pluralize(count, singular, plural)
    "#{count} #{count == 1 ? singular : plural}"
  end
end

require_relative "../core/statistic"

class <<<CLASS_NAME>>> < Statistic
  def initialize
    @title = "Título"
    @category = :results # Una de las claves en core/categories.rb
    @note = "Nota opcional"
    @table_header = {  }
  end

  def query
    <<-SQL
      -- Consulta SQL
    SQL
  end

  def transform(query_results)
    # Transformación opcional en Ruby
  end
end

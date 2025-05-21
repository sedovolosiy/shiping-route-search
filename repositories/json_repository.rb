require 'json'

class JsonRepository
  attr_reader :sailings, :rates, :exchange_rates

  def initialize(json_path)
    data = JSON.parse(File.read(json_path))
    @sailings = data["sailings"].map { |row| Sailing.new(row) }
    @rates = data["rates"].map { |row| Rate.new(row) }
    @exchange_rates = ExchangeRates.new(data["exchange_rates"])
  end
end

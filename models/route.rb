class Route
  attr_reader :sailings

  def initialize(sailings)
    @sailings = sailings
  end

  def total_cost_eur(rates_map, exchange_rates)
    sailings.sum do |sailing|
      rate = rates_map[sailing.sailing_code]
      exchange_rates.to_eur(rate.amount, rate.currency, sailing.departure_date)
    end
  end

  def total_duration
    (Date.parse(sailings.last.arrival_date) - Date.parse(sailings.first.departure_date)).to_i
  end
end

require 'minitest/autorun'
require_relative '../models/sailing'
require_relative '../models/rate'
require_relative '../models/exchange_rates'
require_relative '../models/route'

class RouteTest < Minitest::Test
  def test_total_cost_eur
    sail = Sailing.new({
      "origin_port" => "A",
      "destination_port" => "B",
      "departure_date" => "2022-01-01",
      "arrival_date" => "2022-01-02",
      "sailing_code" => "SC1"
    })
    rate = Rate.new({
      "sailing_code" => "SC1",
      "rate" => "120",
      "rate_currency" => "USD"
    })
    exchange_rates = ExchangeRates.new({ "2022-01-01" => { "usd" => 1.2 } })
    route = Route.new([sail])
    rates_map = { "SC1" => rate }
    assert_in_delta 100, route.total_cost_eur(rates_map, exchange_rates), 0.01
  end

  def test_total_duration
    sail1 = Sailing.new({
      "origin_port" => "A",
      "destination_port" => "B",
      "departure_date" => "2022-01-01",
      "arrival_date" => "2022-01-02",
      "sailing_code" => "SC1"
    })
    sail2 = Sailing.new({
      "origin_port" => "B",
      "destination_port" => "C",
      "departure_date" => "2022-01-03",
      "arrival_date" => "2022-01-05",
      "sailing_code" => "SC2"
    })
    route = Route.new([sail1, sail2])
    assert_equal 4, route.total_duration # 2022-01-05 - 2022-01-01
  end
end

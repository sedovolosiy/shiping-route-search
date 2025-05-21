require 'minitest/autorun'
require_relative '../application/services/route_search/cheapest_route_search'
require_relative '../domain/models/sailing'
require_relative '../domain/models/rate'
require_relative '../application/services/currency/universal_converter'
require_relative '../domain/models/exchange_rates'

class CheapestRouteSearchTest < Minitest::Test
  def setup
    @sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"}),
      Sailing.new({"origin_port"=>"B", "destination_port"=>"C", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-04", "sailing_code"=>"S2"}),
      Sailing.new({"origin_port"=>"A", "destination_port"=>"C", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-04", "sailing_code"=>"S3"})
    ]
    @rates = [
      Rate.new({"sailing_code"=>"S1", "rate"=>"100", "rate_currency"=>"EUR"}),
      Rate.new({"sailing_code"=>"S2", "rate"=>"50", "rate_currency"=>"EUR"}),
      Rate.new({"sailing_code"=>"S3", "rate"=>"200", "rate_currency"=>"EUR"})
    ]
    @rates_map = @rates.map { |r| [r.sailing_code, r] }.to_h
    @exchange_rates = ExchangeRates.new({"2022-01-01"=>{"eur"=>1.0}, "2022-01-03"=>{"eur"=>1.0}})
    @converter = UniversalConverter.new(@exchange_rates, 'EUR')
    @strategy = CheapestRouteSearch.new
  end

  def test_find_cheapest_route
    routes = @strategy.find_routes(@sailings, "A", "C", @rates_map, @converter, 'EUR', max_legs: 3)
    assert_equal 1, routes.size
    # Should pick S1 + S2 (100+50=150) over S3 (200)
    codes = routes.first.map(&:sailing_code)
    assert_equal ["S1", "S2"], codes
  end

  def test_cheapest_route_with_mixed_currencies
    sailings = [
      Sailing.new({"origin_port"=>"CNSHA", "destination_port"=>"NLRTM", "departure_date"=>"2022-02-01", "arrival_date"=>"2022-03-01", "sailing_code"=>"ABCD"}),
      Sailing.new({"origin_port"=>"CNSHA", "destination_port"=>"NLRTM", "departure_date"=>"2022-01-31", "arrival_date"=>"2022-02-28", "sailing_code"=>"IJKL"}),
      Sailing.new({"origin_port"=>"CNSHA", "destination_port"=>"NLRTM", "departure_date"=>"2022-01-29", "arrival_date"=>"2022-02-15", "sailing_code"=>"QRST"})
    ]
    rates = [
      Rate.new({"sailing_code"=>"ABCD", "rate"=>"589.30", "rate_currency"=>"USD"}),
      Rate.new({"sailing_code"=>"IJKL", "rate"=>"97453", "rate_currency"=>"JPY"}),
      Rate.new({"sailing_code"=>"QRST", "rate"=>"761.96", "rate_currency"=>"EUR"})
    ]
    rates_map = rates.map { |r| [r.sailing_code, r] }.to_h
    exchange_rates = ExchangeRates.new({
      "2022-01-29"=>{"usd"=>1.1138, "jpy"=>130.85, "eur"=>1.0},
      "2022-01-31"=>{"usd"=>1.1156, "jpy"=>131.2, "eur"=>1.0},
      "2022-02-01"=>{"usd"=>1.126, "jpy"=>130.15, "eur"=>1.0}
    })
    converter = UniversalConverter.new(exchange_rates, 'EUR')
    strategy = CheapestRouteSearch.new
    routes = strategy.find_routes(sailings, "CNSHA", "NLRTM", rates_map, converter, 'EUR', max_legs: 1)
    assert_equal 1, routes.size
    codes = routes.first.map(&:sailing_code)
    # Check that the cheapest route is selected after conversion to EUR
    # EUR: QRST = 761.96
    # USD: ABCD = 589.30 / 1.126 = 523.47
    # JPY: IJKL = 97453 / 131.2 = 743.01
    # The cheapest: ABCD (USD)
    assert_equal ["ABCD"], codes
  end

  def test_cheapest_route_with_two_legs_cheaper_than_direct
    sailings = [
      # Direct route (expensive)
      Sailing.new({"origin_port"=>"A", "destination_port"=>"C", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-04", "sailing_code"=>"S3"}),
      # Indirect route (cheaper in sum)
      Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"}),
      Sailing.new({"origin_port"=>"B", "destination_port"=>"C", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-04", "sailing_code"=>"S2"})
    ]
    rates = [
      Rate.new({"sailing_code"=>"S1", "rate"=>"100", "rate_currency"=>"EUR"}),
      Rate.new({"sailing_code"=>"S2", "rate"=>"50", "rate_currency"=>"EUR"}),
      Rate.new({"sailing_code"=>"S3", "rate"=>"200", "rate_currency"=>"EUR"})
    ]
    rates_map = rates.map { |r| [r.sailing_code, r] }.to_h
    exchange_rates = ExchangeRates.new({"2022-01-01"=>{"eur"=>1.0}, "2022-01-03"=>{"eur"=>1.0}})
    converter = UniversalConverter.new(exchange_rates, 'EUR')
    strategy = CheapestRouteSearch.new
    routes = strategy.find_routes(sailings, "A", "C", rates_map, converter, 'EUR', max_legs: 3)
    assert_equal 1, routes.size
    codes = routes.first.map(&:sailing_code)
    # Should pick S1 + S2 (100+50=150) over S3 (200)
    assert_equal ["S1", "S2"], codes
  end
end

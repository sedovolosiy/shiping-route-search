require_relative '../../../../test_helper'
require_relative '../../../../application/services/route_search/cheapest_route_search'
require_relative '../../../../domain/models/sailing'
require_relative '../../../../domain/models/rate'
require_relative '../../../../application/services/currency/universal_converter'
require_relative '../../../../domain/models/exchange_rates'

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
    assert_equal ["ABCD"], codes
  end

  def test_cheapest_route_with_two_legs_cheaper_than_direct
    sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"C", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-04", "sailing_code"=>"S3"}),
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
    assert_equal ["S1", "S2"], codes
  end
  
  def test_no_routes_found
    # Test when no routes exist between origin and destination
    sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"}),
      Sailing.new({"origin_port"=>"B", "destination_port"=>"D", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-04", "sailing_code"=>"S2"})
    ]
    routes = @strategy.find_routes(sailings, "A", "C", @rates_map, @converter, 'EUR', max_legs: 3)
    assert_empty routes
  end

  def test_equal_cost_routes
    # Test when there are multiple routes with the same total cost
    sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"C", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"}),
      Sailing.new({"origin_port"=>"A", "destination_port"=>"C", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-04", "sailing_code"=>"S2"})
    ]
    rates = [
      Rate.new({"sailing_code"=>"S1", "rate"=>"100", "rate_currency"=>"EUR"}),
      Rate.new({"sailing_code"=>"S2", "rate"=>"100", "rate_currency"=>"EUR"})
    ]
    rates_map = rates.map { |r| [r.sailing_code, r] }.to_h
    
    routes = @strategy.find_routes(sailings, "A", "C", rates_map, @converter, 'EUR', max_legs: 1)
    assert_equal 2, routes.size
    assert_includes routes.map { |r| r.first.sailing_code }, "S1"
    assert_includes routes.map { |r| r.first.sailing_code }, "S2"
  end

  def test_missing_rate
    sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"C", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"})
    ]
    rates_map = {} # Empty rates map
    
    error = assert_raises(RuntimeError) do
      @strategy.find_routes(sailings, "A", "C", rates_map, @converter, 'EUR', max_legs: 1)
    end
    assert_match(/No rate found for sailing_code/, error.message)
  end

  def test_max_legs_limit
    # Create a chain of ports A->B->C->D->E
    sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"}),
      Sailing.new({"origin_port"=>"B", "destination_port"=>"C", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-04", "sailing_code"=>"S2"}),
      Sailing.new({"origin_port"=>"C", "destination_port"=>"D", "departure_date"=>"2022-01-05", "arrival_date"=>"2022-01-06", "sailing_code"=>"S3"}),
      Sailing.new({"origin_port"=>"D", "destination_port"=>"E", "departure_date"=>"2022-01-07", "arrival_date"=>"2022-01-08", "sailing_code"=>"S4"})
    ]
    rates = [
      Rate.new({"sailing_code"=>"S1", "rate"=>"100", "rate_currency"=>"EUR"}),
      Rate.new({"sailing_code"=>"S2", "rate"=>"100", "rate_currency"=>"EUR"}),
      Rate.new({"sailing_code"=>"S3", "rate"=>"100", "rate_currency"=>"EUR"}),
      Rate.new({"sailing_code"=>"S4", "rate"=>"100", "rate_currency"=>"EUR"})
    ]
    rates_map = rates.map { |r| [r.sailing_code, r] }.to_h
    
    # Test with max_legs: 2
    routes = @strategy.find_routes(sailings, "A", "E", rates_map, @converter, 'EUR', max_legs: 2)
    assert_empty routes # Should find no routes as minimum path requires 4 legs

    # Test with max_legs: 4
    routes = @strategy.find_routes(sailings, "A", "E", rates_map, @converter, 'EUR', max_legs: 4)
    assert_equal 1, routes.size
    assert_equal ["S1", "S2", "S3", "S4"], routes.first.map(&:sailing_code)
  end

  def test_cyclic_routes_prevention
    # Test that the algorithm doesn't get stuck in cycles A->B->A->B...
    sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"}),
      Sailing.new({"origin_port"=>"B", "destination_port"=>"A", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-04", "sailing_code"=>"S2"}),
      Sailing.new({"origin_port"=>"B", "destination_port"=>"C", "departure_date"=>"2022-01-05", "arrival_date"=>"2022-01-06", "sailing_code"=>"S3"})
    ]
    rates = [
      Rate.new({"sailing_code"=>"S1", "rate"=>"100", "rate_currency"=>"EUR"}),
      Rate.new({"sailing_code"=>"S2", "rate"=>"100", "rate_currency"=>"EUR"}),
      Rate.new({"sailing_code"=>"S3", "rate"=>"100", "rate_currency"=>"EUR"})
    ]
    rates_map = rates.map { |r| [r.sailing_code, r] }.to_h
    
    routes = @strategy.find_routes(sailings, "A", "C", rates_map, @converter, 'EUR', max_legs: 4)
    assert_equal 1, routes.size
    route = routes.first.map(&:sailing_code)
    assert_equal ["S1", "S3"], route
  end
end

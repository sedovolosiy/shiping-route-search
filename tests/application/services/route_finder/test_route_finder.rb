require_relative '../../../../test_helper'
require_relative '../../../../application/services/route_finder'
require_relative '../../../../domain/models/sailing'
require_relative '../../../../domain/models/rate'
require_relative '../../../../domain/models/exchange_rates'
require_relative '../../../../application/services/currency/universal_converter'

class DummyStrategy
  def find_routes(*args)
    [[Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"})]]
  end
end

class RouteFinderTest < Minitest::Test
  def setup
    @repo = Minitest::Mock.new
    @repo.expect(:sailings, [Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"})])
    @repo.expect(:rates, [Rate.new({"sailing_code"=>"S1", "rate"=>"100", "rate_currency"=>"USD"})])
    @repo.expect(:rates, [Rate.new({"sailing_code"=>"S1", "rate"=>"100", "rate_currency"=>"USD"})])
    @exchange_rates = ExchangeRates.new({"2022-01-01"=>{"usd"=>1.2}})
    @converter = UniversalConverter.new(@exchange_rates, 'USD')
    @finder = RouteFinder.new(@repo, @converter, 'USD')
  end

  def test_find_cheapest_direct
    input = {origin: 'A', destination: 'B', criteria: 'cheapest-direct'}
    strategy = DummyStrategy.new
    result = @finder.find(input, strategy)
    assert_equal 1, result.size
  end

  def test_find_cheapest
    input = {origin: 'A', destination: 'B', criteria: 'cheapest'}
    strategy = DummyStrategy.new
    result = @finder.find(input, strategy)
    assert_equal 1, result.size
  end

  def test_find_fastest
    input = {origin: 'A', destination: 'B', criteria: 'fastest'}
    strategy = DummyStrategy.new
    result = @finder.find(input, strategy)
    assert_equal 1, result.size
  end

  def test_find_unknown
    input = {origin: 'A', destination: 'B', criteria: 'unknown'}
    strategy = DummyStrategy.new
    result = @finder.find(input, strategy)
    assert_equal [], result
  end
end

require_relative 'test_helper'
require 'minitest/autorun'
require_relative '../domain/contracts/route_search_strategy'
require_relative '../domain/contracts/currency_converter'

class RouteSearchStrategyContractTest < Minitest::Test
  def test_find_routes_raises
    klass = Class.new(RouteSearchStrategy)
    assert_raises(NotImplementedError) { klass.new.find_routes([], '', '') }
  end
end

class CurrencyConverterContractTest < Minitest::Test
  def test_convert_raises
    klass = Class.new(CurrencyConverter)
    assert_raises(NotImplementedError) { klass.new.convert(1, 'USD', 'EUR', '2022-01-01') }
  end
end

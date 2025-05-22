require_relative '../../../../test_helper'
require_relative '../../../../application/services/route_search_strategy_factory'
require_relative '../../../../domain/models/sailing' # Исправленный путь к sailing.rb

class RouteSearchStrategyFactoryTest < Minitest::Test
  def test_build_cheapest_direct
    assert_instance_of DirectRouteSearch, RouteSearchStrategyFactory.build('cheapest-direct')
  end

  def test_build_cheapest
    assert_instance_of CheapestRouteSearch, RouteSearchStrategyFactory.build('cheapest')
  end

  def test_build_fastest
    assert_instance_of FastestRouteSearch, RouteSearchStrategyFactory.build('fastest')
  end

  def test_build_unknown
    assert_raises(RuntimeError) { RouteSearchStrategyFactory.build('unknown') }
  end
end

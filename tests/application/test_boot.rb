require_relative '../test_helper'
require_relative '../../application/boot'

class TestBoot < Minitest::Test
  def test_boot_loads_required_files
    # Check that models are loaded
    assert defined?(Sailing), "Sailing class should be defined after requiring boot.rb"
    assert defined?(Rate), "Rate class should be defined after requiring boot.rb"
    assert defined?(ExchangeRates), "ExchangeRates class should be defined after requiring boot.rb"
    
    # Check that repositories are loaded
    assert defined?(JsonRepository), "JsonRepository class should be defined after requiring boot.rb"
    
    # Check that strategies are loaded
    assert defined?(DirectRouteSearch), "DirectRouteSearch class should be defined after requiring boot.rb"
    assert defined?(CheapestRouteSearch), "CheapestRouteSearch class should be defined after requiring boot.rb"
    assert defined?(FastestRouteSearch), "FastestRouteSearch class should be defined after requiring boot.rb"
    
    # Check that currency converter is loaded
    assert defined?(UniversalConverter), "UniversalConverter class should be defined after requiring boot.rb"
    
    # Check that input/output services are loaded
    assert defined?(InputHandler), "InputHandler class should be defined after requiring boot.rb"
    assert defined?(RouteSearchStrategyFactory), "RouteSearchStrategyFactory class should be defined after requiring boot.rb"
    assert defined?(RouteFinder), "RouteFinder class should be defined after requiring boot.rb"
    assert defined?(OutputHandler), "OutputHandler class should be defined after requiring boot.rb"
  end
end

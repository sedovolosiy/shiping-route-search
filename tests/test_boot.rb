require_relative 'test_helper'
require_relative '../application/boot'

class TestBoot < Minitest::Test
  def test_boot_loads_required_files
    # Test that boot.rb loads all required files properly
    assert defined?(Sailing), "Sailing class should be defined"
    assert defined?(Rate), "Rate class should be defined"
    assert defined?(DirectRouteSearch), "DirectRouteSearch class should be defined"
    assert defined?(CheapestRouteSearch), "CheapestRouteSearch class should be defined"
    assert defined?(FastestRouteSearch), "FastestRouteSearch class should be defined"
    assert defined?(InputHandler), "InputHandler class should be defined"
    assert defined?(OutputHandler), "OutputHandler class should be defined"
  end
end

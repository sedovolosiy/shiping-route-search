require_relative '../../../test_helper'
require_relative '../../../domain/contracts/route_search_strategy'
require_relative '../../../domain/contracts/currency_converter'

class RouteSearchStrategyContractTest < Minitest::Test
  def test_find_routes_raises
    klass = Class.new(RouteSearchStrategy)
    assert_raises(NotImplementedError) { klass.new.find_routes([], '', '') }
  end
end

# Test class for the protected select_best_routes method
class TestableRouteSearchStrategy < RouteSearchStrategy
  # Make select_best_routes public for testing purposes
  public :select_best_routes
end

class SelectBestRoutesTest < Minitest::Test
  def setup
    @strategy = TestableRouteSearchStrategy.new
    # Mock sailing objects (simplified for testing selection logic)
    @s1 = Struct.new(:id, :value).new('s1', 10)
    @s2 = Struct.new(:id, :value).new('s2', 20)
    @s3 = Struct.new(:id, :value).new('s3', 10)
    @s4 = Struct.new(:id, :value).new('s4', 5)
    @s5 = Struct.new(:id, :value).new('s5', nil) # Path that cannot be valued
  end

  def test_empty_paths
    result = @strategy.select_best_routes([]) { |path| path.value }
    assert_empty result, "Should return empty for empty paths"
  end

  def test_nil_paths
    result = @strategy.select_best_routes(nil) { |path| path.value }
    assert_empty result, "Should return empty for nil paths"
  end

  def test_single_best_path
    paths = [[@s4], [@s1], [@s2]] # s4 is the best (value 5)
    result = @strategy.select_best_routes(paths) { |path_sailings| path_sailings.first.value }
    assert_equal [[@s4]], result
  end

  def test_multiple_equally_best_paths
    paths = [[@s1], [@s2], [@s3]] # s1 and s3 are equally best (value 10)
    result = @strategy.select_best_routes(paths) { |path_sailings| path_sailings.first.value }
    assert_includes result, [@s1]
    assert_includes result, [@s3]
    assert_equal 2, result.size
  end

  def test_paths_with_nil_calculable_value
    paths = [[@s1], [@s5], [@s4]] # s5's value is nil, s4 is best
    result = @strategy.select_best_routes(paths) { |path_sailings| path_sailings.first.value }
    assert_equal [[@s4]], result, "Should ignore paths where value calculation returns nil"
  end

  def test_all_paths_have_nil_calculable_value
    paths = [[@s5], [@s5]]
    result = @strategy.select_best_routes(paths) { |path_sailings| path_sailings.first.value }
    assert_empty result, "Should return empty if all paths have nil calculable value"
  end
end

class CurrencyConverterContractTest < Minitest::Test
  def test_convert_raises
    klass = Class.new(CurrencyConverter)
    assert_raises(NotImplementedError) { klass.new.convert(1, 'USD', 'EUR', '2022-01-01') }
  end
end

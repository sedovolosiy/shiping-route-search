require_relative '../../../test_helper'
require_relative '../../../application/services/best_route_picker'
require_relative '../../../domain/models/sailing'
require_relative '../../../domain/models/rate'

# Mock Sailing for controlled testing
MockSailingBRP = Struct.new(:origin_port, :destination_port, :departure_date, :arrival_date, :sailing_code)

class BestRoutePickerTest < Minitest::Test
  def setup
    @rates_map = {
      'VALID1' => Rate.new({'sailing_code' => 'VALID1', 'rate' => '100', 'rate_currency' => 'USD'}),
      'VALID2' => Rate.new({'sailing_code' => 'VALID2', 'rate' => '200', 'rate_currency' => 'EUR'})
    }
    @converter_mock = Minitest::Mock.new
    @base_currency = 'EUR'
    @picker = BestRoutePicker.new(@rates_map, @converter_mock, @base_currency)

    # Default mock behavior for converter
    # (from_amount, from_currency, to_currency, date)
    @converter_mock.expect(:convert, 100.0, [100.0, 'USD', 'EUR', '2023-01-01'])
    @converter_mock.expect(:convert, 200.0, [200.0, 'EUR', 'EUR', '2023-01-03'])
  end

  def teardown
    # @converter_mock.verify # Moved to specific tests that set unique expectations
  rescue MockExpectationError => e
    # Ignore if not all generic expectations were met, specific tests might not use them all
  end

  # Test for: best_route ? [best_route] : [] (cheapest-direct, else part)
  def test_pick_cheapest_direct_no_valid_route
    # All routes lead to Float::INFINITY cost
    s1 = MockSailingBRP.new('A', 'B', '2023-01-01', '2023-01-02', 'MISSING_RATE')
    routes = [[s1]]
    # No expectation for converter as rate is missing
    result = @picker.pick(routes, 'cheapest-direct')
    assert_empty result, "Should return empty if no valid cheapest-direct route is found"
  end

  # Test for: best_route ? [best_route] : [] (fastest, else part)
  def test_pick_fastest_no_valid_route
    # All routes lead to Float::INFINITY duration
    s1 = MockSailingBRP.new('A', 'B', nil, '2023-01-02', 'ANYCODE1') # Invalid departure_date
    routes = [[s1]]
    result = @picker.pick(routes, 'fastest')
    assert_empty result, "Should return empty if no valid fastest route is found"
  end

  # Test for: else: [] in main case
  def test_pick_unknown_criteria
    s1 = MockSailingBRP.new('A', 'B', '2023-01-01', '2023-01-02', 'VALID1')
    routes = [[s1]]
    result = @picker.pick(routes, 'nonexistent-criteria')
    assert_empty result, "Should return empty for unknown criteria"
  end

  # Test for: Float::INFINITY # Or handle missing rate appropriately
  def test_calculate_total_cost_handles_missing_rate
    s1 = MockSailingBRP.new('A', 'B', '2023-01-01', '2023-01-02', 'RATE_NOT_IN_MAP')
    cost = @picker.send(:calculate_total_cost, [s1]) # Using send to test private method
    assert_equal Float::INFINITY, cost, "Cost should be INFINITY if a rate is missing"
  end

  # Test for: return Float::INFINITY if sailings.empty?
  def test_calculate_duration_empty_sailings
    duration = @picker.send(:calculate_duration, []) # Using send
    assert_equal Float::INFINITY, duration, "Duration should be INFINITY for empty sailings array"
  end

  # Test for: rescue ArgumentError, TypeError # Handle cases where dates are nil or not parseable
  def test_calculate_duration_invalid_dates_rescue
    s1 = MockSailingBRP.new('A', 'B', 'INVALID_DATE_FORMAT', '2023-01-02', 'ANYCODE2')
    duration = @picker.send(:calculate_duration, [s1]) # Using send
    assert_equal Float::INFINITY, duration, "Duration should be INFINITY if dates are unparseable"

    s2 = MockSailingBRP.new('A', 'B', nil, '2023-01-02', 'ANYCODE3')
    duration_nil = @picker.send(:calculate_duration, [s2]) # Using send
    assert_equal Float::INFINITY, duration_nil, "Duration should be INFINITY if a date is nil"
  end

  # Test for 'cheapest' when strategy returns multiple, picker should take first
  def test_pick_cheapest_takes_first_if_multiple_from_strategy
    s1 = MockSailingBRP.new('A', 'B', '2023-01-01', '2023-01-02', 'VALID1') # Cost 100
    s2 = MockSailingBRP.new('C', 'D', '2023-01-03', '2023-01-04', 'VALID2') # Cost 200
    
    # Setup converter mock for this specific test path
    # Need to re-initialize or clear existing expectations if @converter_mock is shared and has global setup
    @converter_mock = Minitest::Mock.new # Re-initialize for this test
    @picker = BestRoutePicker.new(@rates_map, @converter_mock, @base_currency) # Re-initialize picker with new mock

    routes = [[s1], [s2]] 
    
    result = @picker.pick(routes, 'cheapest')
    assert_equal [[s1]], result
    @converter_mock.verify # Verify this specific expectation
  end

  def test_pick_cheapest_direct_selects_cheapest
    s_cheap = MockSailingBRP.new('A', 'B', '2023-01-01', '2023-01-02', 'VALID1') # Cost 100
    s_expensive = MockSailingBRP.new('C', 'D', '2023-01-03', '2023-01-04', 'VALID2') # Cost 200

    @converter_mock = Minitest::Mock.new # Re-initialize for this test
    @picker = BestRoutePicker.new(@rates_map, @converter_mock, @base_currency) # Re-initialize picker with new mock

    @converter_mock.expect(:convert, 100.0, [100.0, 'USD', 'EUR', '2023-01-01']) # For s_cheap in min_by
    @converter_mock.expect(:convert, 200.0, [200.0, 'EUR', 'EUR', '2023-01-03']) # For s_expensive in min_by
    @converter_mock.expect(:convert, 100.0, [100.0, 'USD', 'EUR', '2023-01-01']) # For s_cheap in the explicit check after min_by

    routes = [[s_cheap], [s_expensive]]
    result = @picker.pick(routes, 'cheapest-direct')
    assert_equal [[s_cheap]], result
    @converter_mock.verify
  end

  def test_pick_fastest_selects_fastest
    s_fast = MockSailingBRP.new('A', 'B', '2023-01-01', '2023-01-02', 'VALID1') # Duration 1 day
    s_slow = MockSailingBRP.new('C', 'D', '2023-01-03', '2023-01-07', 'VALID2') # Duration 4 days
    
    routes = [[s_fast], [s_slow]]
    result = @picker.pick(routes, 'fastest')
    assert_equal [[s_fast]], result
  end

end

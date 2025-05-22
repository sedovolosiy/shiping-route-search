require 'test_helper'
require_relative '../../../../application/services/route_search/graph_traversal'
require_relative '../../../../domain/models/sailing' # Assuming Sailing model is here

# Mock Sailing class for testing
MockSailing = Struct.new(:origin_port, :destination_port, :departure_date, :arrival_date, :sailing_code, :rate, :rate_currency)

class TestGraphTraversal < Minitest::Test
  include GraphTraversal

  def setup
    # CNSHA -> JPTKO
    @sailing1 = MockSailing.new('CNSHA', 'JPTKO', '2022-01-01', '2022-01-05', 'AAAA', '100.00', 'USD')
    # JPTKO -> USLGB
    @sailing2 = MockSailing.new('JPTKO', 'USLGB', '2022-01-06', '2022-01-10', 'BBBB', '200.00', 'USD')
    # CNSHA -> NLRTM
    @sailing3 = MockSailing.new('CNSHA', 'NLRTM', '2022-01-02', '2022-01-08', 'CCCC', '150.00', 'EUR')
    # NLRTM -> USLGB
    @sailing4 = MockSailing.new('NLRTM', 'USLGB', '2022-01-09', '2022-01-15', 'DDDD', '250.00', 'EUR')
    # USLGB -> CNSHA (for cycle testing)
    @sailing_cycle = MockSailing.new('USLGB', 'CNSHA', '2022-01-16', '2022-01-20', 'EEEE', '300.00', 'USD')

    @sailings = [@sailing1, @sailing2, @sailing3, @sailing4]
  end

  def test_find_all_paths_direct_route
    paths = find_all_paths([@sailing1], 'CNSHA', 'JPTKO', 2)
    assert_equal 1, paths.length
    assert_equal [[@sailing1]], paths
  end

  def test_find_all_paths_indirect_route
    paths = find_all_paths(@sailings, 'CNSHA', 'USLGB', 2)
    assert_equal 2, paths.length
    assert_includes paths, [@sailing1, @sailing2]
    assert_includes paths, [@sailing3, @sailing4]
  end

  def test_find_all_paths_no_route_found
    paths = find_all_paths(@sailings, 'CNSHA', 'DEHAM', 2)
    assert_empty paths
  end

  def test_find_all_paths_max_legs_reached
    # CNSHA -> JPTKO -> USLGB (2 legs)
    # With max_legs = 1, only direct CNSHA -> JPTKO should not be found as destination is USLGB
    # and CNSHA -> NLRTM should not be found.
    # If we search for JPTKO with max_legs = 1, it should be found.
    paths_to_jptko = find_all_paths(@sailings, 'CNSHA', 'JPTKO', 1)
    assert_equal 1, paths_to_jptko.length
    assert_equal [[@sailing1]], paths_to_jptko

    # No path of 1 leg from CNSHA to USLGB
    paths_to_uslgb_1_leg = find_all_paths(@sailings, 'CNSHA', 'USLGB', 1)
    assert_empty paths_to_uslgb_1_leg

    # Paths of 2 legs from CNSHA to USLGB
    paths_to_uslgb_2_legs = find_all_paths(@sailings, 'CNSHA', 'USLGB', 2)
    assert_equal 2, paths_to_uslgb_2_legs.length
  end

  def test_find_all_paths_origin_not_in_sailings
    paths = find_all_paths(@sailings, 'XXXXX', 'USLGB', 2)
    assert_empty paths
  end

  def test_find_all_paths_destination_not_in_sailings_reachable
    # This tests if the destination port itself doesn't have outgoing sailings, but is reachable
    paths = find_all_paths(@sailings, 'CNSHA', 'USLGB', 2) # USLGB is a destination
    assert_equal 2, paths.length
  end
  
  def test_find_all_paths_avoids_cycles
    sailings_with_cycle = @sailings + [@sailing_cycle] # CNSHA -> JPTKO -> USLGB -> CNSHA
    # We are looking for CNSHA -> USLGB. The path CNSHA -> JPTKO -> USLGB is valid.
    # The path CNSHA -> JPTKO -> USLGB -> CNSHA -> JPTKO -> USLGB would be a cycle if not handled.
    # Max_legs is set high to allow longer paths if not for cycle detection.
    paths = find_all_paths(sailings_with_cycle, 'CNSHA', 'USLGB', 5)
    
    # Expected paths:
    # 1. CNSHA --AAAA--> JPTKO --BBBB--> USLGB
    # 2. CNSHA --CCCC--> NLRTM --DDDD--> USLGB
    assert_equal 2, paths.length
    paths.each do |path|
      sailing_codes = path.map(&:sailing_code)
      has_cycle = sailing_codes.uniq.length != sailing_codes.length
      assert !has_cycle, "Path #{sailing_codes.join(' -> ')} has a cycle"
      assert_equal 'CNSHA', path.first.origin_port
      assert_equal 'USLGB', path.last.destination_port
    end
    assert_includes paths.map { |p| p.map(&:sailing_code) }, %w[AAAA BBBB]
    assert_includes paths.map { |p| p.map(&:sailing_code) }, %w[CCCC DDDD]
  end

  def test_find_all_paths_empty_sailings_list
    paths = find_all_paths([], 'CNSHA', 'JPTKO', 2)
    assert_empty paths
  end

  def test_find_all_paths_start_equals_destination_no_sailings
    # If origin and destination are the same, and no sailings, should be empty.
    # The current implementation would not add an empty path for this.
    paths = find_all_paths([], 'CNSHA', 'CNSHA', 2)
    assert_empty paths 
  end

  def test_find_all_paths_start_equals_destination_with_sailings
    # If origin and destination are the same, but there are sailings,
    # it should not return any path unless there's a loop back to the start.
    # The current logic finds paths *between* ports.
    paths = find_all_paths(@sailings, 'CNSHA', 'CNSHA', 2)
    assert_empty paths # No direct sailing from CNSHA to CNSHA in the list
  end

  def test_find_all_paths_complex_scenario_multiple_routes_different_lengths
    s5 = MockSailing.new('USLGB', 'DEHAM', '2022-01-20', '2022-01-25', 'FFFF') # Leg 3 for path 1
    s6 = MockSailing.new('NLRTM', 'DEHAM', '2022-01-16', '2022-01-22', 'GGGG') # Leg 3 for path 2 (alternative)
    s7 = MockSailing.new('JPTKO', 'DEHAM', '2022-01-11', '2022-01-18', 'HHHH') # Alternative 2-leg path
    
    complex_sailings = @sailings + [s5, s6, s7]
    # CNSHA -> JPTKO (s1) -> USLGB (s2) -> DEHAM (s5)  (3 legs)
    # CNSHA -> NLRTM (s3) -> USLGB (s4) -> DEHAM (s5)  (3 legs) - Note: s5 re-used destination, but path is different
    # CNSHA -> NLRTM (s3) -> DEHAM (s6) (2 legs)
    # CNSHA -> JPTKO (s1) -> DEHAM (s7) (2 legs)

    paths = find_all_paths(complex_sailings, 'CNSHA', 'DEHAM', 3)
    assert_equal 4, paths.length
    
    expected_paths_codes = [
      %w[AAAA BBBB FFFF], # CNSHA -> JPTKO -> USLGB -> DEHAM
      %w[CCCC DDDD FFFF], # CNSHA -> NLRTM -> USLGB -> DEHAM
      %w[CCCC GGGG],      # CNSHA -> NLRTM -> DEHAM
      %w[AAAA HHHH]       # CNSHA -> JPTKO -> DEHAM
    ]
    
    actual_paths_codes = paths.map { |p| p.map(&:sailing_code) }.sort
    expected_paths_codes.each do |expected_path|
      assert_includes actual_paths_codes, expected_path.sort
    end
  end
end

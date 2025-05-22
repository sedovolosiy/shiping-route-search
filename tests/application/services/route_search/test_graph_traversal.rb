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
    paths = find_all_paths([], 'CNSHA', 'CNSHA', 2)
    assert_empty paths, "Should be empty if origin is destination but no sailings define this loop or path"
  end

  def test_find_all_paths_path_reaches_max_legs_before_destination
    # CNSHA --AAAA--> JPTKO --BBBB--> USLGB
    # Search CNSHA -> USLGB with max_legs = 1. 
    # Path [AAAA] will be formed (size 1). current_port = JPTKO. path.size (1) is not >= max_legs (1). So it proceeds.
    # by_origin[JPTKO] will find BBBB.
    # new_path = [AAAA, BBBB] (size 2).
    # sailing.destination_port (USLGB) == destination (USLGB) -> result << new_path. This is not what we want to test for the break.

    # Let's test CNSHA -> X (non-existent) with max_legs = 1, where CNSHA -> JPTKO is a valid first leg.
    # Path [AAAA] (size 1) is formed. current_port = JPTKO.
    # The loop `until queue.empty?` continues.
    # `current_port, path = queue.shift` will eventually process `['JPTKO', [@sailing1]]`
    # `break if path.size >= max_legs` -> `break if 1 >= 1` is true. So it should break.
    # This means it won't even try to iterate `by_origin['JPTKO']&.each` for this path.

    # To properly test the `break`, we need to ensure that a path of size `max_legs`
    # whose last port is NOT the destination, does not get extended.
    sailings = [
      MockSailing.new('A', 'B', 'd1', 'a1', 'S1'), # Path A->B
      MockSailing.new('B', 'C', 'd2', 'a2', 'S2')  # Path B->C
    ]
    # Search A -> C with max_legs = 1.
    # Queue starts with [A, []]
    # 1. current=A, path=[] (size 0). 0 < 1. OK.
    #    Process S1 (A->B). new_path=[S1]. Dest B != C. Queue << [B, [S1]]
    # 2. current=B, path=[S1] (size 1). `break if 1 >= 1` is TRUE. Loop breaks for this path.
    #    It should not proceed to find S2.
    # So, find_all_paths should return [].
    paths = find_all_paths(sailings, 'A', 'C', 1)
    assert_empty paths, "Should not find A->C if max_legs=1 cuts off exploration at B"
  end

  def test_find_all_paths_intermediate_port_with_no_outgoing_sailings
    # CNSHA --AAAA--> JPTKO. No sailings from JPTKO.
    # Search CNSHA -> USLGB.
    sailings = [@sailing1] # Only CNSHA -> JPTKO
    paths = find_all_paths(sailings, 'CNSHA', 'USLGB', 2)
    assert_empty paths, "Should be empty if intermediate port JPTKO has no outgoing sailings to reach USLGB"

    # More explicit: A -> B, C -> D. Search A -> D.
    s_ab = MockSailing.new('A', 'B', 'd1', 'a1', 'S_AB')
    s_cd = MockSailing.new('C', 'D', 'd2', 'a2', 'S_CD')
    sailings_no_link = [s_ab, s_cd]
    paths_no_link = find_all_paths(sailings_no_link, 'A', 'D', 2)
    assert_empty paths_no_link, "Should be empty if B has no outgoing sailings to D"
  end

  # Test to ensure the `next if path.any?` for cycle detection is covered.
  # The existing test_find_all_paths_avoids_cycles is good.
  # This one adds a direct self-loop to see if it's handled by the same `next` condition.
  def test_find_all_paths_with_direct_self_loop_sailing
    s_loop = MockSailing.new('JPTKO', 'JPTKO', 'd_loop', 'a_loop', 'SLOOP')
    sailings_with_self_loop = [@sailing1, s_loop, @sailing2] # A->B, B->B (loop), B->C
    # Search A -> C. Expected: A --S1--> B --S2--> C
    paths = find_all_paths(sailings_with_self_loop, 'CNSHA', 'USLGB', 3)
    assert_equal 1, paths.size
    assert_equal [@sailing1, @sailing2], paths.first
    paths.first.each do |s|
      assert s.sailing_code != 'SLOOP', "Path should not include the self-loop sailing SLOOP"
    end
  end
end

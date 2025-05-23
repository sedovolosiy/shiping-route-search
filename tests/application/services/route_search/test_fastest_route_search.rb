require_relative '../../../../test_helper'
require_relative '../../../../application/services/route_search/fastest_route_search'
require_relative '../../../../domain/models/sailing'

class FastestRouteSearchTest < Minitest::Test
  def setup
    @strategy = FastestRouteSearch.new
  end

  def test_find_fastest_route
    sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"}),
      Sailing.new({"origin_port"=>"B", "destination_port"=>"C", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-04", "sailing_code"=>"S2"}),
      Sailing.new({"origin_port"=>"A", "destination_port"=>"C", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-03", "sailing_code"=>"S3"})
    ]
    routes = @strategy.find_routes(sailings, "A", "C", max_legs: 3)
    assert_equal 1, routes.size
    codes = routes.first.map(&:sailing_code)
    assert_equal ["S3"], codes
  end

  def test_multiple_fastest_routes
    sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"D", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-03", "sailing_code"=>"S1"}),
      Sailing.new({"origin_port"=>"D", "destination_port"=>"B", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-05", "sailing_code"=>"S2"})
    ]
    routes = @strategy.find_routes(sailings, "A", "B", max_legs: 4)

    assert_equal 1, routes.size
    codes = routes.map { |r| r.map(&:sailing_code) }
    assert_equal [["S1", "S2"]], codes
  end

    def test_no_fastest_route_when_arrival_and_departure_dates_do_not_match
      sailings = [
        Sailing.new({"origin_port"=>"A", "destination_port"=>"D", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-03", "sailing_code"=>"S1"}),
        Sailing.new({"origin_port"=>"D", "destination_port"=>"B", "departure_date"=>"2022-01-02", "arrival_date"=>"2022-01-05", "sailing_code"=>"S2"}) # departure_date does not match previous arrival_date
      ]
      routes = @strategy.find_routes(sailings, "A", "B", max_legs: 4)
      assert_equal 0, routes.size
    end

  def test_fastest_route_with_multiple_legs_and_multiple_results
    sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-03", "sailing_code"=>"S1"}),
      Sailing.new({"origin_port"=>"B", "destination_port"=>"C", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-05", "sailing_code"=>"S2"}),
      Sailing.new({"origin_port"=>"A", "destination_port"=>"D", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-03", "sailing_code"=>"S3"}),
      Sailing.new({"origin_port"=>"D", "destination_port"=>"C", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-05", "sailing_code"=>"S4"}),
      Sailing.new({"origin_port"=>"A", "destination_port"=>"C", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-06", "sailing_code"=>"S5"})
    ]
    routes = @strategy.find_routes(sailings, "A", "C", max_legs: 3)
    assert_equal 2, routes.size
    codes = routes.map { |r| r.map(&:sailing_code) }.sort
    assert_includes codes, ["S1", "S2"]
    assert_includes codes, ["S3", "S4"]
  end

  def test_find_routes_with_invalid_date
    sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>nil, "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"}),
      Sailing.new({"origin_port"=>"B", "destination_port"=>"C", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-04", "sailing_code"=>"S2"})
    ]
    routes = @strategy.find_routes(sailings, "A", "C", max_legs: 3)
    assert_empty routes
  end
end

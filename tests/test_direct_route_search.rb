require 'minitest/autorun'
require_relative 'test_helper'
require_relative '../application/services/route_search/direct_route_search'
require_relative '../domain/models/sailing'

class DirectRouteSearchTest < Minitest::Test
  def setup
    @sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"}),
      Sailing.new({"origin_port"=>"A", "destination_port"=>"C", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S2"}),
      Sailing.new({"origin_port"=>"C", "destination_port"=>"B", "departure_date"=>"2022-01-03", "arrival_date"=>"2022-01-04", "sailing_code"=>"S3"})
    ]
    @strategy = DirectRouteSearch.new
  end

  def test_find_routes_direct
    routes = @strategy.find_routes(@sailings, "A", "B")
    assert_equal 1, routes.size
    assert_equal "B", routes.first.first.destination_port
  end

  def test_find_routes_none
    routes = @strategy.find_routes(@sailings, "B", "A")
    assert_equal 0, routes.size
  end
end

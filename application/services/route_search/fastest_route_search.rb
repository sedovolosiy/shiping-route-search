require_relative '../../../domain/contracts/route_search_strategy'
require_relative './graph_traversal'
require 'date'

class FastestRouteSearch < RouteSearchStrategy
  include GraphTraversal

  def find_routes(sailings, origin, destination, max_legs: 4)
    all_paths = find_all_paths(sailings, origin, destination, max_legs)

    min_duration = nil
    fastest_routes = []
    all_paths.each do |route_sailings|
      start_date = Date.parse(route_sailings.first.departure_date)
      end_date = Date.parse(route_sailings.last.arrival_date)
      duration = (end_date - start_date).to_i
      if min_duration.nil? || duration < min_duration
        min_duration = duration
        fastest_routes = [route_sailings]
      elsif duration == min_duration
        fastest_routes << route_sailings
      end
    end

    fastest_routes
  end
end

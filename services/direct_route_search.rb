require_relative 'route_search_strategy'

class DirectRouteSearch < RouteSearchStrategy
  def find_routes(sailings, origin, destination)
    sailings.select { |s| s.origin_port == origin && s.destination_port == destination }
            .map { |s| [s] }
  end
end

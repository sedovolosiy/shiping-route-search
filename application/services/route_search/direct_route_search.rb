require_relative '../../../domain/contracts/route_search_strategy'

class DirectRouteSearch < RouteSearchStrategy
  def find_routes(sailings, origin, destination, options = {})
    # options are not used in this strategy
    sailings.select { |s| s.origin_port == origin && s.destination_port == destination }
            .map { |s| [s] }
  end
end

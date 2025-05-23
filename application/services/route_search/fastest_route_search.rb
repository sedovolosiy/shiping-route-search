require_relative '../../../domain/contracts/route_search_strategy'
require_relative './graph_traversal'
require 'date'

class FastestRouteSearch < RouteSearchStrategy
  include GraphTraversal

  def find_routes(sailings, origin, destination, options = {})
    # Get max_legs from options, or environment variable, or default to 4
    default_max_legs = ENV['MAX_LEGS'] ? ENV['MAX_LEGS'].to_i : 4
    max_legs = options.fetch(:max_legs, default_max_legs)
    all_paths = find_all_paths(sailings, origin, destination, max_legs)

    # Use the new helper method from the base class
    select_best_routes(all_paths) do |route_sailings|
      begin
        start_date = Date.parse(route_sailings.first.departure_date)
        end_date = Date.parse(route_sailings.last.arrival_date)
        (end_date - start_date).to_i
      rescue ArgumentError, TypeError # Catch errors if dates are nil or invalid
        nil # Path cannot be timed
      end
    end
  end
end

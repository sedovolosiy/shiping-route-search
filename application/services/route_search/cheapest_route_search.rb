require_relative '../../../domain/contracts/route_search_strategy'
require_relative './graph_traversal'

class CheapestRouteSearch < RouteSearchStrategy
  include GraphTraversal

  def find_routes(sailings, origin, destination, options = {})
    rates_map = options[:rates_map]
    converter = options[:converter]
    target_currency = options[:target_currency]
    # Get max_legs from options, or environment variable, or default to 4
    default_max_legs = ENV['MAX_LEGS'] ? ENV['MAX_LEGS'].to_i : 4
    max_legs = options.fetch(:max_legs, default_max_legs)

    all_paths = find_all_paths(sailings, origin, destination, max_legs)

    # Use the new helper method from the base class
    select_best_routes(all_paths) do |route_sailings|
      route_sailings.sum do |sailing|
        rate = rates_map[sailing.sailing_code]
        unless rate
          # Restore raising an error as expected by the test
          raise "No rate found for sailing_code: #{sailing.sailing_code.inspect} in route #{route_sailings.map(&:sailing_code).inspect}"
        end
        converter.convert(rate.amount, rate.currency, target_currency, sailing.departure_date)
      end
    end
  end
end

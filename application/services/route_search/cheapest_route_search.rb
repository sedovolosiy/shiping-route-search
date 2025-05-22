require_relative '../../../domain/contracts/route_search_strategy'
require_relative './graph_traversal'

class CheapestRouteSearch < RouteSearchStrategy
  include GraphTraversal

  def find_routes(sailings, origin, destination, options = {})
    rates_map = options[:rates_map]
    converter = options[:converter]
    target_currency = options[:target_currency]
    max_legs = options.fetch(:max_legs, 4)

    all_paths = find_all_paths(sailings, origin, destination, max_legs)

    min_cost = nil
    cheapest_routes = []
    all_paths.each do |route_sailings|
      total = route_sailings.sum do |sailing|
        rate = rates_map[sailing.sailing_code]
        unless rate
          raise "No rate found for sailing_code: #{sailing.sailing_code.inspect} in route #{route_sailings.map(&:sailing_code).inspect}"
        end
        converter.convert(rate.amount, rate.currency, target_currency, sailing.departure_date)
      end
      if min_cost.nil? || total < min_cost
        min_cost = total
        cheapest_routes = [route_sailings]
      elsif total == min_cost
        cheapest_routes << route_sailings
      end
    end

    cheapest_routes
  end
end

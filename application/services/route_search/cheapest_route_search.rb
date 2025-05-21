require_relative '../../../domain/contracts/route_search_strategy'

class CheapestRouteSearch < RouteSearchStrategy
  def find_routes(sailings, origin, destination, rates_map, converter, target_currency, max_legs: 4)
    by_origin = sailings.group_by(&:origin_port)
    result = []
    queue = [[origin, []]]

    until queue.empty?
      current_port, path = queue.shift
      break if path.size >= max_legs
      by_origin[current_port]&.each do |sailing|
        next if path.any? { |s| s.sailing_code == sailing.sailing_code }
        new_path = path + [sailing]
        if sailing.destination_port == destination
          result << new_path
        else
          queue << [sailing.destination_port, new_path]
        end
      end
    end

    min_cost = nil
    cheapest_routes = []
    result.each do |route_sailings|
      total = route_sailings.sum do |sailing|
        rate = rates_map[sailing.sailing_code]
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

require_relative 'route_search_strategy'
require 'date'

class FastestRouteSearch < RouteSearchStrategy
  def find_routes(sailings, origin, destination, max_legs: 4)
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

    min_duration = nil
    fastest_routes = []
    result.each do |route_sailings|
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

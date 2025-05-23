require 'json'
require_relative 'output_serializer'

class JsonResultSerializer < OutputSerializer
  def self.serialize(routes, rates_map) # Changed 'sailings' to 'routes' for clarity
    # If routes is empty or contains only nil/empty routes, return an empty JSON array
    return JSON.pretty_generate([]) if routes.nil? || routes.empty?

    serialized_routes_data = routes.map do |single_route_sailings|
      # single_route_sailings is an array of Sailing objects for one route
      # If a route is nil or empty, represent it as an empty array in JSON.
      if single_route_sailings.nil? || single_route_sailings.empty?
        []
      else
        single_route_sailings.map do |sailing|
          rate = rates_map[sailing.sailing_code]
          unless rate
            # This case should ideally be handled before serialization or ensure rates_map is complete.
            # For robustness, let's add route information to the error message.
            route_codes = single_route_sailings.map(&:sailing_code).join(', ')
            raise "Rate not found for sailing code '#{sailing.sailing_code}' during serialization of route: [#{route_codes}]"
          end
          {
            origin_port: sailing.origin_port,
            destination_port: sailing.destination_port,
            departure_date: sailing.departure_date,
            arrival_date: sailing.arrival_date,
            sailing_code: sailing.sailing_code,
            rate: '%.2f' % rate.amount,
            rate_currency: rate.currency
          }
        end
      end
    end
    JSON.pretty_generate(serialized_routes_data)
  end
end

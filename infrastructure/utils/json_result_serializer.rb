require 'json'
require_relative 'output_serializer'

class JsonResultSerializer < OutputSerializer
  def self.serialize(routes, rates_map) # Changed 'sailings' to 'routes' for clarity
    # If routes is empty or contains only nil/empty routes, return an empty JSON array
    return JSON.pretty_generate([]) if routes.nil? || routes.empty?

    # Handle environment variable to determine single vs multiple route output
    return_multiple_routes = ENV['RETURN_MULTIPLE_ROUTES']&.downcase == 'true'

    # Normalize input: ensure we always work with an array of routes
    normalized_routes = if routes.is_a?(Array) && routes.first.is_a?(Array)
      # routes is already an array of routes (each route is an array of Sailing objects)
      routes
    elsif routes.is_a?(Array) && (routes.empty? || routes.first.respond_to?(:sailing_code))
      # routes is a single route (array of Sailing objects)
      [routes]
    else
      # Fallback: treat as array of routes
      routes
    end

    serialized_routes_data = normalized_routes.map do |single_route_sailings|
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

    # Return single route or multiple routes based on environment variable
    result = if return_multiple_routes
      serialized_routes_data
    else
      # Return only the first route, or empty array if no routes
      serialized_routes_data.empty? ? [] : serialized_routes_data.first
    end

    JSON.pretty_generate(result)
  end
end

require_relative '../../../domain/contracts/route_search_strategy'

class DirectRouteSearch < RouteSearchStrategy
  def find_routes(sailings, origin, destination, options = {})
    # options are not used in this strategy
    sailings.select do |s|
      s.origin_port == origin &&
        s.destination_port == destination &&
        valid_sailing_dates?(s) # Add date validation
    end.map { |s| [s] }
  end

  private

  def valid_sailing_dates?(sailing)
    begin
      Date.parse(sailing.arrival_date) >= Date.parse(sailing.departure_date)
    rescue ArgumentError
      # Handle invalid date strings if necessary, though ideally data is clean.
      # For now, we\\'ll consider unparseable dates as invalid.
      false
    end
  end
end

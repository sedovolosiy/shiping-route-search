require 'date'

class BestRoutePicker
  def initialize(rates_map, converter, base_currency)
    @rates_map = rates_map
    @converter = converter
    @base_currency = base_currency
  end

  def pick(routes, criteria)
    return [] if routes.nil? || routes.empty?

    case criteria
    when 'cheapest-direct'
      best_route = routes.min_by do |sailings|
        calculate_total_cost(sailings)
      end
      # Ensure the best_route found is actually valid (not infinite cost)
      return [] if best_route.nil? || calculate_total_cost(best_route) == Float::INFINITY
      [best_route]
    when 'cheapest'
      [routes.first] # Or, if strategy returns multiple equally cheap, apply more logic here.
    when 'fastest'
      best_route = routes.min_by do |sailings|
        calculate_duration(sailings)
      end
      # Ensure the best_route found is actually valid (not infinite duration)
      return [] if best_route.nil? || calculate_duration(best_route) == Float::INFINITY
      [best_route]
    else
      [] # Or handle unknown criteria as an error
    end
  end

  private

  def calculate_total_cost(sailings)
    sailings.sum do |sailing|
      rate = @rates_map[sailing.sailing_code]
      # Ensure rate is not nil before trying to access its properties
      if rate
        @converter.convert(rate.amount, rate.currency, @base_currency, sailing.departure_date)
      else
        Float::INFINITY # Or handle missing rate appropriately
      end
    end
  end

  def calculate_duration(sailings)
    # Assuming sailings is an array of Sailing objects and is not empty
    return Float::INFINITY if sailings.empty?
    # Ensure departure_date and arrival_date are present and parseable
    first_departure = sailings.first.departure_date
    last_arrival = sailings.last.arrival_date
    (Date.parse(last_arrival) - Date.parse(first_departure)).to_i
  rescue ArgumentError, TypeError # Handle cases where dates are nil or not parseable
    Float::INFINITY
  end
end

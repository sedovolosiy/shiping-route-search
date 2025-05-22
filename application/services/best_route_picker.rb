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
      # For cheapest-direct, the strategy already provides direct routes.
      # We need to find the one with the minimum total cost.
      best_route = routes.min_by do |sailings|
        calculate_total_cost(sailings)
      end
      best_route ? [best_route] : []
    when 'cheapest'
      # Assuming the strategy for 'cheapest' already returns routes sorted by price
      # or only the cheapest ones. WRT-0002 implies returning only one.
      [routes.first] # Or, if strategy returns multiple equally cheap, apply more logic here.
    when 'fastest'
      # For fastest, we need to find the one with the minimum duration.
      best_route = routes.min_by do |sailings|
        calculate_duration(sailings)
      end
      best_route ? [best_route] : []
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

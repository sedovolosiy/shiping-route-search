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
      # Calculate costs for all routes
      costs = routes.map { |sailings| calculate_total_cost(sailings) }
      min_cost = costs.min
      # Filter routes that have the minimum cost
      best_routes = routes.select.with_index do |_, index|
        costs[index] == min_cost && costs[index] != Float::INFINITY
      end
      best_routes
    when 'cheapest'
      return [] if routes.first.nil? # handles if strategy returns [nil]

      costs = routes.map { |sailings| calculate_total_cost(sailings) }
      min_cost = costs.min
      best_routes = routes.select.with_index do |_, index|
        costs[index] == min_cost && costs[index] != Float::INFINITY
      end
      best_routes
    when 'fastest'
      # Calculate durations for all routes
      durations = routes.map { |sailings| calculate_duration(sailings) }
      min_duration = durations.min
      # Filter routes that have the minimum duration
      best_routes = routes.select.with_index do |_, index|
        durations[index] == min_duration && durations[index] != Float::INFINITY
      end
      best_routes
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

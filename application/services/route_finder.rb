require 'date'
require_relative 'best_route_picker'
require 'logger'

class RouteFinder
  def initialize(repo, converter, base_currency)
    @repo = repo
    @converter = converter
    @base_currency = base_currency
    @rates_map = repo.rates.map { |r| [r.sailing_code, r] }.to_h
    # Initialize BestRoutePicker here
    @best_route_picker = BestRoutePicker.new(@rates_map, @converter, @base_currency)
    @logger = Logger.new(STDERR) # Initialize logger
  end

  def find(input, strategy)
    origin = input[:origin]
    destination = input[:destination]
    criteria = input[:criteria]

    # Common options for strategies that might need them
    options = {
      rates_map: @rates_map,
      converter: @converter,
      target_currency: @base_currency
      # max_legs can be added here if it becomes a common parameter
    }

    all_routes = case criteria
                 when 'cheapest-direct', 'fastest', 'cheapest'
                   strategy.find_routes(@repo.sailings, origin, destination, options)
                 else
                   @logger.warn("Unknown criteria '#{criteria}' received. Returning empty results.")
                   [] # Handle unknown criteria or unsupported strategy
                 end

    # Delegate picking the best route to BestRoutePicker
    @best_route_picker.pick(all_routes, criteria)
  end
end

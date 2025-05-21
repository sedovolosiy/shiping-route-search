# application/services/route_finder.rb
require 'date'

class RouteFinder
  def initialize(repo, converter, base_currency)
    @repo = repo
    @converter = converter
    @base_currency = base_currency
    @rates_map = repo.rates.map { |r| [r.sailing_code, r] }.to_h
  end

  def find(input, strategy)
    origin = input[:origin]
    destination = input[:destination]
    criteria = input[:criteria]
    case criteria
    when 'cheapest-direct'
      all_routes = strategy.find_routes(@repo.sailings, origin, destination)
      best_route = all_routes.min_by do |sailings|
        sailings.sum do |sailing|
          rate = @rates_map[sailing.sailing_code]
          @converter.convert(rate.amount, rate.currency, @base_currency, sailing.departure_date)
        end
      end
      best_route ? [best_route] : []
    when 'cheapest'
      all_routes = strategy.find_routes(@repo.sailings, origin, destination, @rates_map, @converter, @base_currency)
      all_routes.empty? ? [] : [all_routes.first]
    when 'fastest'
      all_routes = strategy.find_routes(@repo.sailings, origin, destination)
      best_route = all_routes.min_by do |sailings|
        Date.parse(sailings.last.arrival_date) - Date.parse(sailings.first.departure_date)
      end
      best_route ? [best_route] : []
    else
      []
    end
  end
end

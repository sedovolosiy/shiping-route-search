require 'json'
require 'date'

# Models
require_relative 'models/sailing'
require_relative 'models/rate'
require_relative 'models/exchange_rates'
require_relative 'models/route'

# Repository
require_relative 'repositories/json_repository'

# Strategies
require_relative 'services/direct_route_search'
require_relative 'services/cheapest_route_search'
require_relative 'services/fastest_route_search'
require_relative 'services/minimal_legs_route_search'

# Serializer
require_relative 'utils/result_serializer'

origin = STDIN.gets&.strip
destination = STDIN.gets&.strip
criteria = STDIN.gets&.strip

if origin.nil? || destination.nil? || criteria.nil?
  puts "[]"
  exit 0
end

repo = JsonRepository.new('data.json')
rates_map = repo.rates.map { |r| [r.sailing_code, r] }.to_h

search_strategy = case criteria
when 'cheapest-direct'
  DirectRouteSearch.new
when 'cheapest'
  CheapestRouteSearch.new
when 'fastest'
  FastestRouteSearch.new
else
  raise "Unknown search criteria: #{criteria}"
end

routes =
  case criteria
  when 'cheapest-direct'
    all_routes = search_strategy.find_routes(repo.sailings, origin, destination)
    best_route = all_routes.min_by do |sailings|
      sailings.sum do |sailing|
        rate = rates_map[sailing.sailing_code]
        repo.exchange_rates.to_eur(rate.amount, rate.currency, sailing.departure_date)
      end
    end
    best_route ? [best_route] : []
  when 'cheapest'
    all_routes = search_strategy.find_routes(repo.sailings, origin, destination, rates_map, repo.exchange_rates)
    all_routes.empty? ? [] : [all_routes.first]
  when 'fastest'
    all_routes = search_strategy.find_routes(repo.sailings, origin, destination)
    best_route = all_routes.min_by do |sailings|
      Date.parse(sailings.last.arrival_date) - Date.parse(sailings.first.departure_date)
    end
    best_route ? [best_route] : []
  else
    []
  end

if routes.empty? || routes.first.nil?
  puts "[]"
else
  puts JSON.pretty_generate(ResultSerializer.as_json(routes.first, rates_map))
end

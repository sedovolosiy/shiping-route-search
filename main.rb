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

# Currency converter
require_relative 'services/universal_converter'

# Serializer
require_relative 'utils/result_serializer'

VALID_CRITERIA = %w[cheapest-direct cheapest fastest]

origin = STDIN.gets&.strip
destination = STDIN.gets&.strip
criteria = STDIN.gets&.strip

missing = []
missing << "origin" if origin.nil? || origin.empty?
missing << "destination" if destination.nil? || destination.empty?
missing << "criteria" if criteria.nil? || criteria.empty?

unless missing.empty?
  warn "\nMissing required input(s): #{missing.join(', ')}"
  warn "Please enter:"
  warn "  1st line: origin port (e.g. CNSHA)"
  warn "  2nd line: destination port (e.g. NLRTM)"
  warn "  3rd line: search criteria (one of: #{VALID_CRITERIA.join(', ')})"
  warn "\nExample:\n  CNSHA\n  NLRTM\n  cheapest"
  exit 1
end

unless VALID_CRITERIA.include?(criteria)
  warn "\nInvalid search criteria: '#{criteria}'."
  warn "Allowed values are: #{VALID_CRITERIA.join(', ')}"
  warn "Example input:"
  warn "  CNSHA"
  warn "  NLRTM"
  warn "  cheapest"
  exit 1
end


repo = JsonRepository.new('data.json')
base_currency = 'EUR'
converter = UniversalConverter.new(repo.exchange_rates, base_currency)
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
        converter.convert(rate.amount, rate.currency, base_currency, sailing.departure_date)
      end
    end
    best_route ? [best_route] : []
  when 'cheapest'
    all_routes = search_strategy.find_routes(repo.sailings, origin, destination, rates_map, converter, base_currency)
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
  route = Route.new(routes.first)
  puts JSON.pretty_generate(ResultSerializer.as_json(route, rates_map))
end

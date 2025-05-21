# application/boot.rb
require 'json'
require 'date'

# Models
require_relative '../domain/models/sailing'
require_relative '../domain/models/rate'
require_relative '../domain/models/exchange_rates'

# Repository
require_relative '../infrastructure/repositories/json_repository'

# Strategies
require_relative 'services/route_search/direct_route_search'
require_relative 'services/route_search/cheapest_route_search'
require_relative 'services/route_search/fastest_route_search'

# Currency converter
require_relative 'services/currency/universal_converter'

# Input/Output services
require_relative 'services/input_handler'
require_relative 'services/route_search_strategy_factory'
require_relative 'services/route_finder'
require_relative 'services/output_handler'

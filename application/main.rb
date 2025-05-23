require_relative 'boot'

input = InputHandler.parse
repo = JsonRepository.new('debug_data.json')
base_currency = 'EUR'
converter = UniversalConverter.new(repo.exchange_rates, base_currency)
strategy = RouteSearchStrategyFactory.build(input[:criteria])
routes = RouteFinder.new(repo, converter, base_currency).find(input, strategy)
OutputHandler.serialize_and_print(routes, repo.rates.map { |r| [r.sailing_code, r] }.to_h, ENV['OUTPUT_FORMAT'] || 'json')

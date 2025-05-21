# application/services/route_search_strategy_factory.rb
require_relative '../services/route_search/direct_route_search'
require_relative '../services/route_search/cheapest_route_search'
require_relative '../services/route_search/fastest_route_search'

class RouteSearchStrategyFactory
  def self.build(criteria)
    case criteria
    when 'cheapest-direct'
      DirectRouteSearch.new
    when 'cheapest'
      CheapestRouteSearch.new
    when 'fastest'
      FastestRouteSearch.new
    else
      raise "Unknown search criteria: #{criteria}"
    end
  end
end

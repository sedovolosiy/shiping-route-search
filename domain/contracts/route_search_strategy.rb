class RouteSearchStrategy
  def find_routes(sailings, origin, destination, options = {})
    raise NotImplementedError
  end
end

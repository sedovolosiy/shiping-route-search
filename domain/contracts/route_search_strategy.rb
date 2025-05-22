class RouteSearchStrategy
  def find_routes(sailings, origin, destination, options = {})
    raise NotImplementedError
  end

  protected

  # Helper method to select the best routes based on a calculated value (e.g., cost, duration)
  # It takes all possible paths and a block to calculate the value for each path.
  def select_best_routes(all_paths, &value_calculator)
    return [] if all_paths.nil? || all_paths.empty?

    min_value = nil
    best_routes = []

    all_paths.each do |path_sailings|
      # The block (value_calculator) is called here to get the specific value (cost, duration, etc.)
      current_value = yield(path_sailings)

      next if current_value.nil? # Skip if value cannot be calculated for a path

      if min_value.nil? || current_value < min_value
        min_value = current_value
        best_routes = [path_sailings]
      elsif current_value == min_value
        best_routes << path_sailings
      end
    end

    best_routes
  end
end

class RouteSearchStrategy
  def find_routes(sailings, origin, destination, options = {})
    raise NotImplementedError
  end

  protected

  # Helper method to select the best routes based on a calculated value (e.g., cost, duration)
  # It takes all possible paths and a block to calculate the value for each path.
  #
  # @param all_paths [Array<Array<Sailing>>] A list of all possible paths, where each path is an array of Sailing objects.
  # @param value_calculator [Proc] A block that accepts a single path (an array of Sailing objects)
  #   and returns a numeric value (e.g., cost, duration) for that path.
  #   If the block returns nil for a path, that path is ignored.
  # @return [Array<Array<Sailing>>] An array containing the best path(s) based on the minimum value
  #   calculated by the block. Returns an empty array if all_paths is empty or if all paths
  #   result in a nil value from the value_calculator.
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

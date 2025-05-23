module GraphTraversal
  def find_all_paths(sailings, origin, destination, max_legs)
    # Validate max_legs
    if max_legs <= 0
      raise ArgumentError, "max_legs must be greater than 0"
    end

    by_origin = sailings.group_by(&:origin_port)
    result = []
    queue = [[origin, []]] # Each element is [current_port, path_so_far]

    until queue.empty?
      current_port, path = queue.shift

      # Stop exploring this path if it's already too long
      next if path.size >= max_legs

      by_origin[current_port]&.each do |sailing|
        # To prevent cycles, ensure the destination of the current sailing
        # is not a node already visited in the current path (unless it's the final destination).
        # Visited nodes include the initial origin of the search and all intermediate destinations
        # from the current path being explored.
        nodes_already_visited_in_current_path = [origin] + path.map(&:destination_port)

        if sailing.destination_port != destination && nodes_already_visited_in_current_path.include?(sailing.destination_port)
          next
        end

        new_path = path + [sailing]

        if sailing.destination_port == destination
          result << new_path
        else
          # Add the next port and the updated path to the queue
          queue << [sailing.destination_port, new_path]
        end
      end
    end
    result
  end
end

module GraphTraversal
  def find_all_paths(sailings, origin, destination, max_legs)
    by_origin = sailings.group_by(&:origin_port)
    result = []
    queue = [[origin, []]] # Each element is [current_port, path_so_far]

    until queue.empty?
      current_port, path = queue.shift

      # Stop exploring this path if it's already too long
      next if path.size >= max_legs

      by_origin[current_port]&.each do |sailing|
        # Avoid visiting the same intermediate port twice.
        # An intermediate port is any port visited that is not the final destination of the overall search.
        visited_destinations_in_path = path.map(&:destination_port)
        if sailing.destination_port != destination && visited_destinations_in_path.include?(sailing.destination_port)
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

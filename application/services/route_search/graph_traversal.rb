module GraphTraversal
  def find_all_paths(sailings, origin, destination, max_legs)
    by_origin = sailings.group_by(&:origin_port)
    result = []
    queue = [[origin, []]] # Each element is [current_port, path_so_far]

    until queue.empty?
      current_port, path = queue.shift

      # Stop exploring this path if it's already too long
      break if path.size >= max_legs

      by_origin[current_port]&.each do |sailing|
        # Avoid cycles by checking if this sailing is already in the current path
        next if path.any? { |s| s.sailing_code == sailing.sailing_code }

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

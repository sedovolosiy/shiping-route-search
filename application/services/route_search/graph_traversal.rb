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
        # Skip sailings with missing dates
        if sailing.departure_date.nil? || sailing.arrival_date.nil?
          next # Skip this sailing as dates are missing
        end
        
        # Validate that arrival_date is not before departure_date for the current sailing
        begin
          if Date.parse(sailing.arrival_date) < Date.parse(sailing.departure_date)
            next # Skip this sailing as its dates are inconsistent
          end
        rescue ArgumentError, TypeError
          # Handle invalid date strings or type errors if necessary
          next # Skip if dates are unparseable
        end

        # To prevent cycles, ensure the destination of the current sailing
        # is not a node already visited in the current path (unless it's the final destination).
        # Visited nodes include the initial origin of the search and all intermediate destinations
        # from the current path being explored.
        nodes_already_visited_in_current_path = [origin] + path.map(&:destination_port)

        if sailing.destination_port != destination && nodes_already_visited_in_current_path.include?(sailing.destination_port)
          next
        end

        # Date consistency check:
        # The departure date of the current sailing must be on or after the arrival date of the previous sailing in the path.
        if path.any?
          last_sailing_in_path = path.last
          # We already checked sailing.departure_date for nil above
          # but need to check the last_sailing_in_path.arrival_date
          if last_sailing_in_path.arrival_date.nil?
            next # Skip if the previous sailing's arrival date is missing
          end
          
          begin
            if Date.parse(sailing.departure_date) < Date.parse(last_sailing_in_path.arrival_date)
              next # Skip this sailing as it departs before the previous one arrives
            end
          rescue ArgumentError, TypeError
            # Handle invalid date strings or type errors if necessary, though ideally data is clean.
            # For now, we'll skip if dates are unparseable, treating it as an invalid path.
            next
          end
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

require_relative 'input_parser'

class StdinInputParser < InputParser
  def self.parse
    origin = $stdin.gets&.strip
    destination = $stdin.gets&.strip
    criteria = $stdin.gets&.strip
    [origin, destination, criteria]
  end
end

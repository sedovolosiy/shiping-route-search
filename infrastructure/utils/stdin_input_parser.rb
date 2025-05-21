require_relative 'input_parser'

class StdinInputParser < InputParser
  def self.parse
    origin = STDIN.gets&.strip
    destination = STDIN.gets&.strip
    criteria = STDIN.gets&.strip
    [origin, destination, criteria]
  end
end

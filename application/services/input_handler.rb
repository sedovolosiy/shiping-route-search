# application/services/input_handler.rb
class InputHandler
  VALID_CRITERIA = %w[cheapest-direct cheapest fastest]

  def self.parse
    input_type = ENV['INPUT_TYPE'] || 'stdin'
    input_parser =
      case input_type
      when 'stdin'
        require_relative '../../infrastructure/utils/stdin_input_parser'
        StdinInputParser
      when 'file'
        raise 'File input not implemented yet'
      when 'api'
        raise 'API input not implemented yet'
      when 'url'
        raise 'URL input not implemented yet'
      else
        raise "Unknown input type: #{input_type}"
      end

    origin, destination, criteria = input_parser.parse
    missing = []
    missing << 'origin' if origin.nil? || origin.empty?
    missing << 'destination' if destination.nil? || destination.empty?
    missing << 'criteria' if criteria.nil? || criteria.empty?
    unless missing.empty?
      warn "\nMissing required input(s): #{missing.join(', ')}"
      warn "Please enter:"
      warn "  1st line: origin port (e.g. CNSHA)"
      warn "  2nd line: destination port (e.g. NLRTM)"
      warn "  3rd line: search criteria (one of: #{VALID_CRITERIA.join(', ')})"
      warn "\nExample:\n  CNSHA\n  NLRTM\n  cheapest"
      exit 1
    end
    unless VALID_CRITERIA.include?(criteria)
      warn "\nInvalid search criteria: '#{criteria}'."
      warn "Allowed values are: #{VALID_CRITERIA.join(', ')}"
      warn "Example input:"
      warn "  CNSHA"
      warn "  NLRTM"
      warn "  cheapest"
      exit 1
    end
    { origin: origin, destination: destination, criteria: criteria }
  end
end

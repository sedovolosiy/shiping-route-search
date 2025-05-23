# application/services/output_handler.rb
require_relative '../../infrastructure/utils/json_result_serializer'

class OutputHandler
  def self.serialize_and_print(routes, rates_map, output_format = 'json')
    serializer =
      case output_format
      when 'json'
        JsonResultSerializer
      when 'csv'
        raise 'CSV output not implemented yet'
      when 'xml'
        raise 'XML output not implemented yet'
      else
        raise "Unknown output format: #{output_format}"
      end
    
    puts serializer.serialize(routes, rates_map)
  end
end

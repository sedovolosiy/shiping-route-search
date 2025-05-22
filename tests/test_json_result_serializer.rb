require_relative 'test_helper'
require 'simplecov'
SimpleCov.start do
  add_filter '/tests/'
  track_files 'application/**/*.rb'
end

require 'minitest/autorun'
require_relative '../infrastructure/utils/json_result_serializer'
require_relative '../domain/models/sailing'
require_relative '../domain/models/rate'

class JsonResultSerializerTest < Minitest::Test
  def test_serialize
    sailings = [
      Sailing.new({"origin_port"=>"A", "destination_port"=>"B", "departure_date"=>"2022-01-01", "arrival_date"=>"2022-01-02", "sailing_code"=>"S1"})
    ]
    rates_map = {
      "S1" => Rate.new({"sailing_code"=>"S1", "rate"=>"123.45", "rate_currency"=>"USD"})
    }
    json = JsonResultSerializer.serialize(sailings, rates_map)
    assert_includes json, '"origin_port": "A"'
    assert_includes json, '"rate": "123.45"'
    assert_includes json, '"rate_currency": "USD"'
  end
end

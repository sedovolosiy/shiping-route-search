require 'minitest/autorun'
require_relative '../models/sailing'

class SailingTest < Minitest::Test
  def test_initialization
    s = Sailing.new({
      "origin_port" => "CNSHA",
      "destination_port" => "NLRTM",
      "departure_date" => "2022-01-01",
      "arrival_date" => "2022-01-15",
      "sailing_code" => "ABC1"
    })
    assert_equal "CNSHA", s.origin_port
    assert_equal "NLRTM", s.destination_port
    assert_equal "2022-01-01", s.departure_date
    assert_equal "2022-01-15", s.arrival_date
    assert_equal "ABC1", s.sailing_code
  end
end

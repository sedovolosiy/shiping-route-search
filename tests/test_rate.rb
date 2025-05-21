require_relative 'test_helper'
require 'minitest/autorun'
require_relative '../domain/models/rate'

class RateTest < Minitest::Test
  def test_initialization
    r = Rate.new({
      "sailing_code" => "ABC1",
      "rate" => "123.45",
      "rate_currency" => "USD"
    })
    assert_equal "ABC1", r.sailing_code
    assert_in_delta 123.45, r.amount, 0.01
    assert_equal "USD", r.currency
  end
end

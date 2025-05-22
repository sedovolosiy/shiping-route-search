require 'minitest/autorun'
require_relative '../domain/models/exchange_rates'
require_relative '../application/services/currency/universal_converter'

class TestIsolatedExchange < Minitest::Test
  def test_jpy_usd_conversion
    # Create a minimal setup that reproduces the issue
    exchange_rates = ExchangeRates.new({
      "2022-01-03" => {"usd" => 1.25, "eur" => 1.0, "jpy" => 130}
    })
    converter = UniversalConverter.new(exchange_rates, 'EUR')
    
    # The conversion that was failing
    result = converter.convert(13000, 'JPY', 'USD', '2022-01-03')
    assert_in_delta 125, result, 0.01
    
    puts "Test passed: JPY to USD conversion works"
  end
end

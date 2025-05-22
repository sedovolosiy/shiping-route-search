require_relative 'test_helper'
require_relative '../application/services/currency/universal_converter'
require_relative '../domain/models/exchange_rates'

class UniversalConverterTest < Minitest::Test
  def setup
    @exchange_rates = ExchangeRates.new({
      "2022-01-01" => {"usd" => 1.2, "eur" => 1.0},
      "2022-01-02" => {"usd" => 1.3, "eur" => 1.0}
    })
    @converter = UniversalConverter.new(@exchange_rates, 'EUR')
  end

  def test_convert_same_currency
    assert_in_delta 100, @converter.convert(100, 'EUR', 'EUR', '2022-01-01'), 0.01
  end

  def test_convert_base_to_other
    assert_in_delta 120, @converter.convert(100, 'EUR', 'USD', '2022-01-01'), 0.01
  end

  def test_convert_other_to_base
    assert_in_delta 100, @converter.convert(120, 'USD', 'EUR', '2022-01-01'), 0.01
  end

  def test_convert_other_to_other
    assert_in_delta 100, @converter.convert(100, 'USD', 'USD', '2022-01-01'), 0.01
  end
end

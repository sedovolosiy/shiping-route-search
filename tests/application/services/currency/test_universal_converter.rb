require_relative '../../../../test_helper'
require 'minitest/autorun'
require_relative '../../../../application/services/currency/universal_converter'
require_relative '../../../../domain/models/exchange_rates'

class UniversalConverterTest < Minitest::Test
  def setup
    @exchange_rates = ExchangeRates.new({
      "2022-01-01" => {"usd" => 1.2, "eur" => 1.0, "gbp" => 0.85},
      "2022-01-02" => {"usd" => 1.3, "eur" => 1.0},
      "2022-01-03" => {"usd" => 1.25, "eur" => 1.0, "jpy" => 130}
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
    # Converting USD to GBP (should go through EUR as base)
    # USD → EUR → GBP
    # 100 USD = 83.33 EUR = 70.83 GBP
    assert_in_delta 70.83, @converter.convert(100, 'USD', 'GBP', '2022-01-01'), 0.01
  end

  def test_convert_other_currencies
    # Test JPY to USD conversion through EUR
    # 13000 JPY → 100 EUR → 125 USD
    assert_in_delta 125, @converter.convert(13000, 'JPY', 'USD', '2022-01-03'), 0.01
  end

  def test_missing_source_currency_rate
    error = assert_raises(RuntimeError) do
      @converter.convert(100, 'CAD', 'EUR', '2022-01-01')
    end
    assert_equal 'No rate for CAD on 2022-01-01', error.message
  end

  def test_missing_target_currency_rate
    error = assert_raises(RuntimeError) do
      @converter.convert(100, 'EUR', 'CAD', '2022-01-01')
    end
    assert_equal 'No rate for CAD on 2022-01-01', error.message
  end

  def test_missing_date
    error = assert_raises(RuntimeError) do
      @converter.convert(100, 'EUR', 'USD', '2023-01-01')
    end
    assert_equal 'No rates for 2023-01-01', error.message
  end

  def test_missing_currency_rate_on_specific_date
    error = assert_raises(RuntimeError) do
      @converter.convert(100, 'USD', 'GBP', '2022-01-02') # GBP rate missing on this date
    end
    assert_equal 'No rate for GBP on 2022-01-02', error.message
  end

  def test_convert_with_different_precision
    # Test conversion that requires more decimal precision
    # If 1 USD = 130 JPY, then 1 JPY = 1/130 USD ≈ 0.007692 USD
    rates = ExchangeRates.new({
      "2022-01-01" => {"usd" => 1.0, "jpy" => 130.0, "eur" => 1.0}
    })
    converter = UniversalConverter.new(rates, 'EUR')
    
    # Converting small JPY amount to USD
    assert_in_delta 0.77, converter.convert(100, 'JPY', 'USD', '2022-01-01'), 0.01
  end

  def test_convert_large_numbers
    # Test with larger numbers to ensure precision is maintained
    rates = ExchangeRates.new({
      "2022-01-01" => {"usd" => 1.2345, "eur" => 1.0}
    })
    converter = UniversalConverter.new(rates, 'EUR')
    
    assert_in_delta 12345.00, converter.convert(10000, 'EUR', 'USD', '2022-01-01'), 0.01
  end
end

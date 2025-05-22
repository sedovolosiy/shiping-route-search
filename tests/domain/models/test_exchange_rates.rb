require_relative '../../../test_helper'
require_relative '../../../domain/models/exchange_rates'

class ExchangeRatesTest < Minitest::Test
  def test_rate_success
    rates = ExchangeRates.new({"2022-01-01" => {"usd" => 1.2, "eur" => 1.0}})
    assert_equal 1.2, rates.rate("2022-01-01", "usd")
    assert_equal 1.0, rates.rate("2022-01-01", "eur")
  end

  def test_rate_no_date
    rates = ExchangeRates.new({"2022-01-01" => {"usd" => 1.2}})
    assert_raises(RuntimeError) { rates.rate("2022-01-02", "usd") }
  end

  def test_rate_no_currency
    rates = ExchangeRates.new({"2022-01-01" => {"usd" => 1.2}})
    assert_raises(RuntimeError) { rates.rate("2022-01-01", "eur") }
  end
end

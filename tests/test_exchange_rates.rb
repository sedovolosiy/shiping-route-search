require 'minitest/autorun'
require_relative '../models/exchange_rates'

class ExchangeRatesTest < Minitest::Test
  def setup
    @rates = {
      "2022-01-01" => { "usd" => 1.2, "jpy" => 130.0 }
    }
    @ex = ExchangeRates.new(@rates)
  end

  def test_to_eur_usd
    assert_in_delta 100.0 / 1.2, @ex.to_eur(100, "USD", "2022-01-01"), 0.01
  end

  def test_to_eur_jpy
    assert_in_delta 260.0 / 130.0, @ex.to_eur(260, "JPY", "2022-01-01"), 0.01
  end

  def test_to_eur_eur
    assert_equal 123, @ex.to_eur(123, "EUR", "2022-01-01")
  end
end

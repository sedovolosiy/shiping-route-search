require_relative '../../../domain/contracts/currency_converter'

class UniversalConverter < CurrencyConverter
  def initialize(exchange_rates, base_currency)
    @exchange_rates = exchange_rates
    @base_currency = base_currency.downcase
  end

  def convert(amount, from_currency, to_currency, date)
    from_currency_upper = from_currency.upcase
    from_currency = from_currency.downcase
    to_currency = to_currency.downcase
    
    return amount if from_currency == to_currency

    if from_currency == @base_currency
      # base → to
      rate = @exchange_rates.rate(date, to_currency)
      (amount * rate).round(2)
    elsif to_currency == @base_currency
      # from → base
      rate = @exchange_rates.rate(date, from_currency)
      raise "No rate for #{from_currency_upper} on #{date}" unless rate
      (amount / rate).round(2)
    else
      # from → base → to
      base_amount = convert(amount, from_currency, @base_currency, date)
      convert(base_amount, @base_currency, to_currency, date)
    end
  end
end

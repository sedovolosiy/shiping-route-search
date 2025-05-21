class ExchangeRates
  def initialize(data)
    @data = data
  end

  # amount: float, currency: "USD"|"EUR"|"JPY", date: "YYYY-MM-DD"
  def to_eur(amount, currency, date)
    return amount if currency == "EUR"
    rates = @data[date]
    raise "No rates for #{date}" unless rates
    key = currency.downcase
    raise "No rate for #{currency} on #{date}" unless rates[key]
    (amount / rates[key]).round(2)
  end
end

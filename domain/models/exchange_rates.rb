class ExchangeRates
  def initialize(rates_by_date)
    @rates_by_date = rates_by_date
  end

  def rate(date, currency)
    rates = @rates_by_date[date]
    raise "No rates for #{date}" unless rates
    rate = rates[currency.downcase]
    raise "No rate for #{currency} on #{date}" unless rate
    rate
  end
end

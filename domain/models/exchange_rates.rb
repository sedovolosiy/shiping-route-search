class ExchangeRates
  def initialize(rates_by_date)
    # Convert all date strings to consistent format
    @rates_by_date = {}
    rates_by_date.each do |date, rates|
      @rates_by_date[date.to_s] = rates
    end
  end

  def rate(date, currency)
    currency_upper = currency.upcase
    currency = currency.downcase
    date = date.to_s
    
    rates = @rates_by_date[date]
    raise "No rates for #{date}" unless rates
    rate = rates[currency]
    raise "No rate for #{currency_upper} on #{date}" unless rate
    rate
  end
end

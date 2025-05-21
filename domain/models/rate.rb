class Rate
  attr_reader :sailing_code, :amount, :currency

  def initialize(attrs)
    @sailing_code = attrs["sailing_code"]
    @amount = attrs["rate"].to_f
    @currency = attrs["rate_currency"]
  end
end

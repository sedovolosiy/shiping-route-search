class CurrencyConverter
  def convert(amount, from_currency, to_currency, date)
    raise NotImplementedError, 'Override in subclass'
  end
end

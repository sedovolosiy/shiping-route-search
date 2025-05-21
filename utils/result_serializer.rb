class ResultSerializer
  def self.as_json(route, rates_map)
    route.sailings.map do |sailing|
      rate = rates_map[sailing.sailing_code]
      {
        origin_port: sailing.origin_port,
        destination_port: sailing.destination_port,
        departure_date: sailing.departure_date,
        arrival_date: sailing.arrival_date,
        sailing_code: sailing.sailing_code,
        rate: '%.2f' % rate.amount,
        rate_currency: rate.currency
      }
    end
  end
end

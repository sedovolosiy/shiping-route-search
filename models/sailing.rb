class Sailing
  attr_reader :origin_port, :destination_port, :departure_date, :arrival_date, :sailing_code

  def initialize(attrs)
    @origin_port = attrs["origin_port"]
    @destination_port = attrs["destination_port"]
    @departure_date = attrs["departure_date"]
    @arrival_date = attrs["arrival_date"]
    @sailing_code = attrs["sailing_code"]
  end
end

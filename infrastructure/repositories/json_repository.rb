require 'json'
require_relative '../../domain/models/sailing'
require_relative '../../domain/models/rate'
require_relative '../../domain/models/exchange_rates'

class JsonRepository
  attr_reader :sailings, :rates, :exchange_rates

  def initialize(json_path)
    data = JSON.parse(File.read(json_path))
    validate_data!(data)
    @sailings = data["sailings"].map { |row| Sailing.new(row) }
    @rates = data["rates"].map { |row| Rate.new(row) }
    @exchange_rates = ExchangeRates.new(data["exchange_rates"])
  end

  private

  def validate_data!(data)
    unless data.is_a?(Hash)
      raise "Input data must be a JSON object (Hash)"
    end
    %w[sailings rates exchange_rates].each do |key|
      raise "Missing key: #{key}" unless data.key?(key)
    end
    unless data["sailings"].is_a?(Array)
      raise 'sailings must be an array'
    end
    unless data["rates"].is_a?(Array)
      raise 'rates must be an array'
    end
    unless data["exchange_rates"].is_a?(Hash)
      raise 'exchange_rates must be a hash'
    end
    data["sailings"].each_with_index do |s, i|
      %w[origin_port destination_port departure_date arrival_date sailing_code].each do |k|
        raise "Sailing[#{i}] missing key: #{k}" unless s.key?(k)
      end
    end
    data["rates"].each_with_index do |r, i|
      %w[sailing_code rate rate_currency].each do |k|
        raise "Rate[#{i}] missing key: #{k}" unless r.key?(k)
      end
    end
    data["exchange_rates"].each do |date, rates|
      unless rates.is_a?(Hash)
        raise "exchange_rates for #{date} must be a hash"
      end
    end
  end
end

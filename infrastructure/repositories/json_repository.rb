require 'json'
require_relative '../../domain/models/sailing'
require_relative '../../domain/models/rate'
require_relative '../../domain/models/exchange_rates'

class JsonRepository
  attr_reader :sailings, :rates, :exchange_rates

  def initialize(json_path)
    file_content = File.read(json_path)
    data = file_content.strip.empty? ? {} : JSON.parse(file_content) # Handle empty file
    validate_data!(data)
    @sailings = (data["sailings"] || []).map { |row| Sailing.new(row) } # Initialize with empty array if key is missing
    @rates = (data["rates"] || []).map { |row| Rate.new(row) } # Initialize with empty array if key is missing
    @exchange_rates = ExchangeRates.new(data["exchange_rates"] || {}) # Initialize with empty hash if key is missing
  end

  private

  def validate_data!(data)
    unless data.is_a?(Hash)
      raise "Input data must be a JSON object (Hash)"
    end
    unless (data["sailings"].nil? || data["sailings"].is_a?(Array))
      raise 'sailings must be an array'
    end
    unless (data["rates"].nil? || data["rates"].is_a?(Array))
      raise 'rates must be an array'
    end
    unless (data["exchange_rates"].nil? || data["exchange_rates"].is_a?(Hash))
      raise 'exchange_rates must be a hash'
    end
    (data["sailings"] || []).each_with_index do |s, i| # Iterate over empty array if key is missing
      %w[origin_port destination_port departure_date arrival_date sailing_code].each do |k|
        raise "Sailing[#{i}] missing key: #{k}" unless s.key?(k)
      end
    end
    (data["rates"] || []).each_with_index do |r, i| # Iterate over empty array if key is missing
      %w[sailing_code rate rate_currency].each do |k|
        raise "Rate[#{i}] missing key: #{k}" unless r.key?(k)
      end
    end
    (data["exchange_rates"] || {}).each do |date, rates| # Iterate over empty hash if key is missing
      unless rates.is_a?(Hash)
        raise "exchange_rates for #{date} must be a hash"
      end
    end
  end
end

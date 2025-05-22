require_relative '../../../test_helper'
require_relative '../../../infrastructure/repositories/json_repository'
require_relative '../../../domain/models/sailing'
require_relative '../../../domain/models/rate'
require_relative '../../../domain/models/exchange_rates'

class JsonRepositoryTest < Minitest::Test
  def setup
    @json_path = 'test_data.json'
    @data = {
      'sailings' => [
        { 'origin_port' => 'A', 'destination_port' => 'B', 'departure_date' => '2022-01-01', 'arrival_date' => '2022-01-02', 'sailing_code' => 'S1' }
      ],
      'rates' => [
        { 'sailing_code' => 'S1', 'rate' => '100', 'rate_currency' => 'USD' }
      ],
      'exchange_rates' => {
        '2022-01-01' => { 'usd' => 1.2 }
      }
    }
    File.write(@json_path, JSON.dump(@data))
  end

  def teardown
    File.delete(@json_path) if File.exist?(@json_path)
  end

  def test_initialize_and_accessors
    repo = JsonRepository.new(@json_path)
    assert_equal 1, repo.sailings.size
    assert_equal 1, repo.rates.size
    assert_kind_of ExchangeRates, repo.exchange_rates
  end

  def test_invalid_json
    File.write(@json_path, '[]')
    error = assert_raises(RuntimeError) { JsonRepository.new(@json_path) }
    assert_equal "Input data must be a JSON object (Hash)", error.message
  end

  def test_missing_keys
    File.write(@json_path, JSON.dump({})) # data becomes {}
    # Previous behavior expected an error.
    # Now, JsonRepository should initialize with empty collections.
    repo = JsonRepository.new(@json_path)
    assert_empty repo.sailings, "Sailings should be empty for an empty JSON object"
    assert_empty repo.rates, "Rates should be empty for an empty JSON object"
    assert_kind_of ExchangeRates, repo.exchange_rates, "Exchange_rates should be an ExchangeRates object"
    assert_empty repo.exchange_rates.instance_variable_get(:@rates_by_date), "Exchange_rates internal data should be empty"
  end

  def test_empty_json_file
    File.write(@json_path, '') # Empty file
    repo = JsonRepository.new(@json_path)
    assert_empty repo.sailings, "Sailings should be empty for an empty JSON file"
    assert_empty repo.rates, "Rates should be empty for an empty JSON file"
    assert_kind_of ExchangeRates, repo.exchange_rates, "Exchange_rates should be an ExchangeRates object for an empty file"
    assert_empty repo.exchange_rates.instance_variable_get(:@rates_by_date), "Exchange_rates internal data should be empty for an empty file"

    File.write(@json_path, '   ') # File with only whitespace
    repo_whitespace = JsonRepository.new(@json_path)
    assert_empty repo_whitespace.sailings, "Sailings should be empty for a whitespace-only JSON file"
    assert_empty repo_whitespace.rates, "Rates should be empty for a whitespace-only JSON file"
    assert_kind_of ExchangeRates, repo_whitespace.exchange_rates, "Exchange_rates should be an ExchangeRates object for a whitespace-only file"
    assert_empty repo_whitespace.exchange_rates.instance_variable_get(:@rates_by_date), "Exchange_rates internal data should be empty for a whitespace-only file"
  end

  def test_invalid_sailings_type
    @data['sailings'] = {}
    File.write(@json_path, JSON.dump(@data))
    error = assert_raises(RuntimeError) { JsonRepository.new(@json_path) }
    assert_equal 'sailings must be an array', error.message
  end

  def test_invalid_rates_type
    @data['rates'] = 'not an array'
    File.write(@json_path, JSON.dump(@data))
    error = assert_raises(RuntimeError) { JsonRepository.new(@json_path) }
    assert_equal 'rates must be an array', error.message
  end

  def test_invalid_exchange_rates_type
    @data['exchange_rates'] = []
    File.write(@json_path, JSON.dump(@data))
    error = assert_raises(RuntimeError) { JsonRepository.new(@json_path) }
    assert_equal 'exchange_rates must be a hash', error.message
  end

  def test_invalid_exchange_rates_inner_type
    @data['exchange_rates'] = { '2022-01-01' => [] }
    File.write(@json_path, JSON.dump(@data))
    error = assert_raises(RuntimeError) { JsonRepository.new(@json_path) }
    assert_equal 'exchange_rates for 2022-01-01 must be a hash', error.message
  end

  def test_missing_sailing_keys
    %w[origin_port destination_port departure_date arrival_date sailing_code].each do |key|
      invalid_data = @data.dup
      invalid_data['sailings'] = [invalid_data['sailings'].first.reject { |k, _| k == key }]
      File.write(@json_path, JSON.dump(invalid_data))
      error = assert_raises(RuntimeError) { JsonRepository.new(@json_path) }
      assert_match(/Sailing\[0\] missing key: #{key}/, error.message)
    end
  end

  def test_missing_rate_keys
    %w[sailing_code rate rate_currency].each do |key|
      invalid_data = @data.dup
      invalid_data['rates'] = [invalid_data['rates'].first.reject { |k, _| k == key }]
      File.write(@json_path, JSON.dump(invalid_data))
      error = assert_raises(RuntimeError) { JsonRepository.new(@json_path) }
      assert_match(/Rate\[0\] missing key: #{key}/, error.message)
    end
  end

  def test_multiple_valid_entries
    @data['sailings'] << @data['sailings'].first.merge('sailing_code' => 'S2')
    @data['rates'] << @data['rates'].first.merge('sailing_code' => 'S2')
    @data['exchange_rates']['2022-01-02'] = { 'usd' => 1.3 }
    File.write(@json_path, JSON.dump(@data))
    
    repo = JsonRepository.new(@json_path)
    assert_equal 2, repo.sailings.size
    assert_equal 2, repo.rates.size
    # Verify exchange rates data through the rate method
    assert_equal 1.2, repo.exchange_rates.rate('2022-01-01', 'USD')
    assert_equal 1.3, repo.exchange_rates.rate('2022-01-02', 'USD')
  end
end

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
    assert_raises(RuntimeError) { JsonRepository.new(@json_path) }
  end

  def test_missing_keys
    File.write(@json_path, JSON.dump({}))
    assert_raises(RuntimeError) { JsonRepository.new(@json_path) }
  end
end

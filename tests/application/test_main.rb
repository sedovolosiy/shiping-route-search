require_relative '../test_helper'
# We need to mock necessary components before loading main.rb
# because it executes code immediately
# 
require 'json'
require 'open3'
require 'fileutils'

class TestMain < Minitest::Test
  def setup
    # Save the original stdin, stdout, and ENV
    @original_stdin = $stdin
    @original_stdout = $stdout
    @original_env = ENV.to_h
    
    # Create empty debug_data.json file for testing
    File.write(ENV['DATA_FILE'], '{"sailings":[],"rates":[],"exchange_rates":{}}')
    
    # Mock InputHandler to prevent actual execution of main.rb logic
    @mock_input_handler = Minitest::Mock.new
    Object.send(:remove_const, :InputHandler) if Object.const_defined?(:InputHandler)
    Object.const_set(:InputHandler, Class.new do
      def self.parse
        {origin: 'CNSHA', destination: 'NLRTM', criteria: 'cheapest'}
      end
    end)
    
    # Mock other classes to prevent actual execution
    @mock_repository = Minitest::Mock.new
    Object.send(:remove_const, :JsonRepository) if Object.const_defined?(:JsonRepository)
    Object.const_set(:JsonRepository, Class.new do
      def initialize(_)
        # No-op constructor
      end
      def exchange_rates
        # Return a mock exchange rates object
        Object.new
      end
      def rates
        []
      end
      def sailings
        []
      end
    end)
    
    # Mock RouteSearchStrategyFactory
    Object.send(:remove_const, :RouteSearchStrategyFactory) if Object.const_defined?(:RouteSearchStrategyFactory)
    Object.const_set(:RouteSearchStrategyFactory, Class.new do
      def self.build(_)
        # Return a mock strategy
        Object.new
      end
    end)
    
    # Mock RouteFinder
    Object.send(:remove_const, :RouteFinder) if Object.const_defined?(:RouteFinder)
    Object.const_set(:RouteFinder, Class.new do
      def initialize(_, _, _)
        # No-op constructor
      end
      def find(_, _)
        []
      end
    end)
    
    # Mock OutputHandler
    Object.send(:remove_const, :OutputHandler) if Object.const_defined?(:OutputHandler)
    Object.const_set(:OutputHandler, Class.new do
      def self.serialize_and_print(_, _, _)
        # No-op method
      end
    end)
    
    # Mock the standard input with test data
    $stdin = StringIO.new("CNSHA\nNLRTM\ncheapest\n")
    
    # Redirect standard output to capture it
    $stdout = StringIO.new
    
    # Set environment variables
    ENV['INPUT_TYPE'] = 'stdin'
    ENV['OUTPUT_FORMAT'] = 'json'
    ENV['DATA_FILE'] = 'debug_data.json'
  end
  
  def test_main_executes_without_error
    # Now we can safely require main.rb which will execute against our mocks
    require_relative '../../application/main'
    
    # Simply verifying that it loaded without error is sufficient
    assert true, "main.rb executed without raising an exception"
  end
  
  def teardown
    # Clean up the debug_data.json file before restoring ENV
    FileUtils.rm_f(ENV['DATA_FILE'] || 'debug_data.json')
    
    # Restore the original stdin, stdout, and ENV
    $stdin = @original_stdin
    $stdout = @original_stdout
    ENV.clear
    ENV.update(@original_env)
    
    # Clean up our mocks
    Object.send(:remove_const, :InputHandler) if Object.const_defined?(:InputHandler)
    Object.send(:remove_const, :JsonRepository) if Object.const_defined?(:JsonRepository)
    Object.send(:remove_const, :RouteSearchStrategyFactory) if Object.const_defined?(:RouteSearchStrategyFactory)
    Object.send(:remove_const, :RouteFinder) if Object.const_defined?(:RouteFinder)
    Object.send(:remove_const, :OutputHandler) if Object.const_defined?(:OutputHandler)
  end
end

class TestMainApplicationIntegration < Minitest::Test
  # Path to the main.rb script.
  SCRIPT_PATH = File.expand_path('../../application/main.rb', __dir__)

  # Path to the debug_data.json file which will be created for tests in the project root.
  # main.rb (JsonRepository.new('debug_data.json')) will look for it there when run from the root.
  TEST_DATA_FILE_PATH = File.expand_path("../../#{ENV['DATA_FILE'] || 'debug_data.json'}", __dir__)

  def setup
    # Make sure there's no leftover data file before each test
    teardown_data_file
  end

  def teardown
    teardown_data_file
  end

  private

  # Helper for writing test data to debug_data.json
  def write_test_data(data)
    File.write(TEST_DATA_FILE_PATH, JSON.generate(data))
  end

  # Helper for removing the test data file
  def teardown_data_file
    FileUtils.rm_f(TEST_DATA_FILE_PATH)
  end

  # Helper for running the script and getting its output
  def run_script(inputs_array, env_vars = {})
    # Command to run the Ruby script
    command = "ruby #{SCRIPT_PATH}"
    # Format data for STDIN
    stdin_data = inputs_array.join("\n") + "\n"

    # Set DATA_FILE environment variable to use debug_data.json for tests
    env_vars = env_vars.merge({ 'DATA_FILE' => ENV['DATA_FILE'] || 'debug_data.json' })

    # Run the script with environment variables and STDIN data
    # The first argument to Open3.capture3 is the environment variables hash
    stdout_str, stderr_str, status = Open3.capture3(env_vars, command, stdin_data: stdin_data)

    { stdout: stdout_str, stderr: stderr_str, status: status }
  end

  public # Test methods

  # Test 1: The cheapest route (successful search)
  def test_finds_cheapest_direct_route
    test_data = {
      "sailings": [
        { "origin_port": "PORTA", "destination_port": "PORTC", "departure_date": "2023-01-10", "arrival_date": "2023-01-10", "sailing_code": "SAIL_AC" },
        { "origin_port": "PORTA", "destination_port": "PORTC", "departure_date": "2023-01-12", "arrival_date": "2023-01-12", "sailing_code": "SAIL_AD" } # Another one, more expensive
      ],
      "rates": [
        { "sailing_code": "SAIL_AC", "rate": "10.00", "rate_currency": "USD" },
        { "sailing_code": "SAIL_AD", "rate": "100.00", "rate_currency": "USD" }
      ],
      "exchange_rates": {
        "2023-01-10": { "USD": 0.90, "EUR": 1.0 }, # 1 EUR = 0.90 USD
        "2023-01-12": { "USD": 0.90, "EUR": 1.0 }
      }
    }
    write_test_data(test_data)

    inputs = ["PORTA", "PORTC", "cheapest"]
    result = run_script(inputs)

    assert result[:status].success?, "Script finished with an error: #{result[:stderr]}"
    # assert_empty result[:stderr], "STDERR should be empty, but: #{result[:stderr]}" # Uncomment if necessary

    parsed_output = JSON.parse(result[:stdout])
    expected_route = {
      "origin_port" => "PORTA", "destination_port" => "PORTC",
      "departure_date" => "2023-01-10", "arrival_date" => "2023-01-10",
      "sailing_code" => "SAIL_AC", "rate" => "10.00", "rate_currency" => "USD"
    }

    assert_instance_of Array, parsed_output
    assert_equal 1, parsed_output.length
    # Compare only the fields we're interested in, if the output contains more
    assert_equal expected_route["sailing_code"], parsed_output.first["sailing_code"]
    assert_equal expected_route["rate"], parsed_output.first["rate"]
  end

  # Test 2: The fastest route
  def test_finds_fastest_route_with_layover
    # SAIL_AB + SAIL_BC is faster than direct SAIL_AC
    test_data = {
      "sailings": [
        { "origin_port": "PORTA", "destination_port": "PORTC", "departure_date": "2023-01-10", "arrival_date": "2023-01-20", "sailing_code": "SAIL_AC" }, # 10 days
        { "origin_port": "PORTA", "destination_port": "PORTB", "departure_date": "2023-01-10", "arrival_date": "2023-01-12", "sailing_code": "SAIL_AB" }, # 2 days
        { "origin_port": "PORTB", "destination_port": "PORTC", "departure_date": "2023-01-13", "arrival_date": "2023-01-16", "sailing_code": "SAIL_BC" }  # 3 days, total 2+1(waiting)+3=6 days
      ],
      "rates": [
        { "sailing_code": "SAIL_AC", "rate": "50.00", "rate_currency": "USD" },
        { "sailing_code": "SAIL_AB", "rate": "30.00", "rate_currency": "USD" },
        { "sailing_code": "SAIL_BC", "rate": "30.00", "rate_currency": "USD" }
      ],
      "exchange_rates": {
        "2023-01-10": { "USD": 0.90, "EUR": 1.0 },
        "2023-01-13": { "USD": 0.90, "EUR": 1.0 },
        "2023-01-20": { "USD": 0.90, "EUR": 1.0 }
      }
    }
    write_test_data(test_data)

    inputs = ["PORTA", "PORTC", "fastest"]
    result = run_script(inputs)

    assert result[:status].success?, "Script finished with an error: #{result[:stderr]}"
    parsed_output = JSON.parse(result[:stdout])

    # We expect this to be a route with two segments
    assert_instance_of Array, parsed_output
    assert_equal 2, parsed_output.length, "Expected a composite route with 2 segments"
    assert_equal "SAIL_AB", parsed_output[0]["sailing_code"]
    assert_equal "SAIL_BC", parsed_output[1]["sailing_code"]
  end

  # Test 3: Route not found
  def test_no_route_found
    test_data = {
      "sailings": [
        { "origin_port": "PORTA", "destination_port": "PORTB", "departure_date": "2023-01-10", "arrival_date": "2023-01-12", "sailing_code": "SAIL_AB" }
      ],
      "rates": [{ "sailing_code": "SAIL_AB", "rate": "10.00", "rate_currency": "USD" }],
      "exchange_rates": { "2023-01-10": { "USD": 0.90, "EUR": 1.0 } }
    }
    write_test_data(test_data)

    inputs = ["ZZZ", "YYY", "cheapest"]
    result = run_script(inputs)

    assert result[:status].success?, "Script finished with an error: #{result[:stderr]}"
    parsed_output = JSON.parse(result[:stdout])
    assert_instance_of Array, parsed_output
    assert_empty parsed_output, "Expected an empty array if no route is found"
  end
  
  # Test 4: Test cheapest-direct route prioritizes direct routes even if more expensive
  def test_finds_cheapest_direct_route_only
    test_data = {
      "sailings": [
        { "origin_port": "PORTA", "destination_port": "PORTC", "departure_date": "2023-01-10", "arrival_date": "2023-01-20", "sailing_code": "SAIL_AC_DIRECT" }, # Direct but expensive
        { "origin_port": "PORTA", "destination_port": "PORTB", "departure_date": "2023-01-10", "arrival_date": "2023-01-12", "sailing_code": "SAIL_AB" }, 
        { "origin_port": "PORTB", "destination_port": "PORTC", "departure_date": "2023-01-13", "arrival_date": "2023-01-15", "sailing_code": "SAIL_BC" }  # Indirect but cheaper overall
      ],
      "rates": [
        { "sailing_code": "SAIL_AC_DIRECT", "rate": "200.00", "rate_currency": "USD" }, # More expensive direct route
        { "sailing_code": "SAIL_AB", "rate": "50.00", "rate_currency": "USD" },
        { "sailing_code": "SAIL_BC", "rate": "50.00", "rate_currency": "USD" }  # Combined AB+BC = 100 USD, cheaper than direct AC
      ],
      "exchange_rates": {
        "2023-01-10": { "USD": 0.90, "EUR": 1.0 },
        "2023-01-13": { "USD": 0.90, "EUR": 1.0 }
      }
    }
    write_test_data(test_data)

    inputs = ["PORTA", "PORTC", "cheapest-direct"]
    result = run_script(inputs)

    assert result[:status].success?, "Script finished with an error: #{result[:stderr]}"
    parsed_output = JSON.parse(result[:stdout])

    # Should return only the direct route, even though it's more expensive
    assert_instance_of Array, parsed_output
    assert_equal 1, parsed_output.length, "Expected only one direct route"
    assert_equal "SAIL_AC_DIRECT", parsed_output.first["sailing_code"]
  end
end

require_relative 'test_helper'

# Before loading main.rb, we need to set up mocks to prevent 
# actual execution of the code that would try to read from stdin
# and interact with the filesystem

# Mock classes to prevent actual execution
module Mocks
  class InputHandler
    def self.parse
      {origin: 'CNSHA', destination: 'NLRTM', criteria: 'cheapest'}
    end
  end

  class ExchangeRates
    def rate(_, _); 1.0; end
  end

  class JsonRepository
    def initialize(_); end
    def exchange_rates; Mocks::ExchangeRates.new; end
    def rates; []; end
    def sailings; []; end
  end

  class Strategy
    def find_routes(_, _, _); []; end
  end

  class RouteSearchStrategyFactory
    def self.build(_); Mocks::Strategy.new; end
  end

  class RouteFinder
    def initialize(_, _, _); end
    def find(_, _); []; end
  end

  class OutputHandler
    def self.serialize_and_print(_, _, _); end
  end
end

class TestMain < Minitest::Test
  def setup
    # Save original classes if they exist
    @originals = {}
    save_original(:InputHandler)
    save_original(:JsonRepository)
    save_original(:RouteSearchStrategyFactory)
    save_original(:RouteFinder)
    save_original(:OutputHandler)
    
    # Replace with mocks
    Object.const_set(:InputHandler, Mocks::InputHandler)
    Object.const_set(:JsonRepository, Mocks::JsonRepository)
    Object.const_set(:RouteSearchStrategyFactory, Mocks::RouteSearchStrategyFactory)
    Object.const_set(:RouteFinder, Mocks::RouteFinder)
    Object.const_set(:OutputHandler, Mocks::OutputHandler)
    
    # Mock stdin/stdout
    @original_stdin = $stdin
    @original_stdout = $stdout
    $stdin = StringIO.new("CNSHA\nNLRTM\ncheapest\n")
    $stdout = StringIO.new
    
    # Save ENV variables
    @original_env = ENV.to_h
    ENV['INPUT_TYPE'] = 'stdin'
    ENV['OUTPUT_FORMAT'] = 'json'
  end
  
  def test_main_executes_without_error
    # Require main which will execute with our mocks
    require_relative '../application/main'
    assert true, "main.rb executed without errors"
  end
  
  def teardown
    # Restore original classes
    restore_original(:InputHandler)
    restore_original(:JsonRepository)
    restore_original(:RouteSearchStrategyFactory)
    restore_original(:RouteFinder)
    restore_original(:OutputHandler)
    
    # Restore stdin/stdout
    $stdin = @original_stdin
    $stdout = @original_stdout
    
    # Restore ENV
    ENV.clear
    ENV.update(@original_env)
  end
  
  private
  
  def save_original(const_name)
    if Object.const_defined?(const_name)
      @originals[const_name] = Object.const_get(const_name)
      Object.send(:remove_const, const_name)
    end
  end
  
  def restore_original(const_name)
    Object.send(:remove_const, const_name) if Object.const_defined?(const_name)
    Object.const_set(const_name, @originals[const_name]) if @originals[const_name]
  end
end

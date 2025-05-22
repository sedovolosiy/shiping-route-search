require_relative '../test_helper'
# We need to mock necessary components before loading main.rb
# because it executes code immediately

class TestMain < Minitest::Test
  def setup
    # Save the original stdin, stdout, and ENV
    @original_stdin = $stdin
    @original_stdout = $stdout
    @original_env = ENV.to_h
    
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
  end
  
  def test_main_executes_without_error
    # Now we can safely require main.rb which will execute against our mocks
    require_relative '../../application/main'
    
    # Simply verifying that it loaded without error is sufficient
    assert true, "main.rb executed without raising an exception"
  end
  
  def teardown
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

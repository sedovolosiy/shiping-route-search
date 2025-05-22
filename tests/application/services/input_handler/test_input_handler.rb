require_relative '../../../../test_helper'
require_relative '../../../../application/services/input_handler'

class InputHandlerTest < Minitest::Test
  def setup
    # Store original ENV and STDIN
    @original_env = ENV.to_h
    @original_stdin = $stdin
  end

  def test_valid_parse_stdin
    ENV['INPUT_TYPE'] = 'stdin'
    input = "CNSHA\nNLRTM\ncheapest\n"
    $stdin = StringIO.new(input)
    result = InputHandler.parse
    assert_equal({origin: 'CNSHA', destination: 'NLRTM', criteria: 'cheapest'}, result)
  end

  def test_invalid_criteria
    ENV['INPUT_TYPE'] = 'stdin'
    input = "CNSHA\nNLRTM\ninvalid\n"
    $stdin = StringIO.new(input)
    error_output = StringIO.new
    $stderr = error_output
    assert_raises(SystemExit) { InputHandler.parse }
    assert_match(/Invalid search criteria/, error_output.string)
  end

  def test_missing_fields
    ENV['INPUT_TYPE'] = 'stdin'
    input = "\n\n\n"
    $stdin = StringIO.new(input)
    error_output = StringIO.new
    $stderr = error_output
    assert_raises(SystemExit) { InputHandler.parse }
    assert_match(/Missing required input/, error_output.string)
  end

  def test_default_input_type
    ENV.delete('INPUT_TYPE')
    input = "CNSHA\nNLRTM\ncheapest\n"
    $stdin = StringIO.new(input)
    result = InputHandler.parse
    assert_equal({origin: 'CNSHA', destination: 'NLRTM', criteria: 'cheapest'}, result)
  end

  def test_file_input_type
    ENV['INPUT_TYPE'] = 'file'
    error = assert_raises(RuntimeError) { InputHandler.parse }
    assert_equal 'File input not implemented yet', error.message
  end

  def test_api_input_type
    ENV['INPUT_TYPE'] = 'api'
    error = assert_raises(RuntimeError) { InputHandler.parse }
    assert_equal 'API input not implemented yet', error.message
  end

  def test_url_input_type
    ENV['INPUT_TYPE'] = 'url'
    error = assert_raises(RuntimeError) { InputHandler.parse }
    assert_equal 'URL input not implemented yet', error.message
  end

  def test_unknown_input_type
    ENV['INPUT_TYPE'] = 'unknown'
    error = assert_raises(RuntimeError) { InputHandler.parse }
    assert_equal 'Unknown input type: unknown', error.message
  end

  def test_missing_origin
    ENV['INPUT_TYPE'] = 'stdin'
    input = "\nNLRTM\ncheapest\n"
    $stdin = StringIO.new(input)
    error_output = StringIO.new
    $stderr = error_output
    assert_raises(SystemExit) { InputHandler.parse }
    assert_match(/Missing required input.*origin/, error_output.string)
  end

  def test_missing_destination
    ENV['INPUT_TYPE'] = 'stdin'
    input = "CNSHA\n\ncheapest\n"
    $stdin = StringIO.new(input)
    error_output = StringIO.new
    $stderr = error_output
    assert_raises(SystemExit) { InputHandler.parse }
    assert_match(/Missing required input.*destination/, error_output.string)
  end

  def test_missing_criteria
    ENV['INPUT_TYPE'] = 'stdin'
    input = "CNSHA\nNLRTM\n\n"
    $stdin = StringIO.new(input)
    error_output = StringIO.new
    $stderr = error_output
    assert_raises(SystemExit) { InputHandler.parse }
    assert_match(/Missing required input.*criteria/, error_output.string)
  end

  def test_all_valid_criteria
    ENV['INPUT_TYPE'] = 'stdin'
    InputHandler::VALID_CRITERIA.each do |criteria|
      input = "CNSHA\nNLRTM\n#{criteria}\n"
      $stdin = StringIO.new(input)
      result = InputHandler.parse
      assert_equal({origin: 'CNSHA', destination: 'NLRTM', criteria: criteria}, result)
    end
  end

  def teardown
    # Restore original ENV and STDIN
    ENV.clear
    ENV.update(@original_env)
    $stdin = @original_stdin
    $stderr = STDERR
  end
end

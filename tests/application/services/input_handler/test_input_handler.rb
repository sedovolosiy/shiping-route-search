require_relative '../../../../test_helper'
require_relative '../../../../application/services/input_handler'

class InputHandlerTest < Minitest::Test
  def test_valid_parse_stdin
    ENV['INPUT_TYPE'] = 'stdin'
    input = "CNSHA\nNLRTM\ncheapest\n"
    $stdin = StringIO.new(input)
    result = InputHandler.parse
    assert_equal({origin: 'CNSHA', destination: 'NLRTM', criteria: 'cheapest'}, result)
  ensure
    $stdin = STDIN
  end

  def test_invalid_criteria
    ENV['INPUT_TYPE'] = 'stdin'
    input = "CNSHA\nNLRTM\ninvalid\n"
    $stdin = StringIO.new(input)
    assert_raises(SystemExit) { InputHandler.parse }
  ensure
    $stdin = STDIN
  end

  def test_missing_fields
    ENV['INPUT_TYPE'] = 'stdin'
    input = "\n\n\n"
    $stdin = StringIO.new(input)
    assert_raises(SystemExit) { InputHandler.parse }
  ensure
    $stdin = STDIN
  end
end

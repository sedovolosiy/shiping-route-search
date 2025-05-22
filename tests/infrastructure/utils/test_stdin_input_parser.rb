require_relative '../../../test_helper'
require_relative '../../../infrastructure/utils/stdin_input_parser'

class StdinInputParserTest < Minitest::Test
  def test_parse_reads_from_stdin
    input = "CNSHA\nNLRTM\ncheapest\n"
    $stdin = StringIO.new(input)
    result = StdinInputParser.parse
    assert_equal ['CNSHA', 'NLRTM', 'cheapest'], result
  ensure
    $stdin = STDIN
  end
  
  def test_parse_with_nil_input
    # Simulate nil input by setting $stdin to return nil
    mock_stdin = Object.new
    def mock_stdin.gets; nil; end
    
    original_stdin = $stdin
    $stdin = mock_stdin
    
    result = StdinInputParser.parse
    assert_equal [nil, nil, nil], result
  ensure
    $stdin = original_stdin
  end
  
  def test_parse_with_empty_inputs
    input = "\n\n\n"
    $stdin = StringIO.new(input)
    result = StdinInputParser.parse
    assert_equal ['', '', ''], result
  ensure
    $stdin = STDIN
  end
  
  def test_parse_with_mixed_inputs
    # Test with first two inputs present but third missing
    input = "CNSHA\nNLRTM\n"
    $stdin = StringIO.new(input)
    result = StdinInputParser.parse
    assert_equal ['CNSHA', 'NLRTM', nil], result
  ensure
    $stdin = STDIN
  end
  
  def test_parse_with_first_input_nil
    # Custom mock that returns nil only for the first call
    mock_stdin = Object.new
    def mock_stdin.gets
      @call_count ||= 0
      if @call_count == 0
        @call_count += 1
        nil
      else
        @call_count += 1
        "test\n"
      end
    end
    
    original_stdin = $stdin
    $stdin = mock_stdin
    
    result = StdinInputParser.parse
    assert_equal [nil, "test", "test"], result
  ensure
    $stdin = original_stdin
  end
  
  def test_parse_with_second_input_nil
    # Custom mock that returns nil only for the second call
    mock_stdin = Object.new
    def mock_stdin.gets
      @call_count ||= 0
      if @call_count == 1
        @call_count += 1
        nil
      else
        @call_count += 1
        "test\n"
      end
    end
    
    original_stdin = $stdin
    $stdin = mock_stdin
    
    result = StdinInputParser.parse
    assert_equal ["test", nil, "test"], result
  ensure
    $stdin = original_stdin
  end
  
  def test_parse_with_third_input_nil
    # Custom mock that returns nil only for the third call
    mock_stdin = Object.new
    def mock_stdin.gets
      @call_count ||= 0
      if @call_count == 2
        @call_count += 1
        nil
      else
        @call_count += 1
        "test\n"
      end
    end
    
    original_stdin = $stdin
    $stdin = mock_stdin
    
    result = StdinInputParser.parse
    assert_equal ["test", "test", nil], result
  ensure
    $stdin = original_stdin
  end
end

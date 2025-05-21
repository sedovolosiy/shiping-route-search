require 'minitest/autorun'
require_relative '../infrastructure/utils/stdin_input_parser'

class StdinInputParserTest < Minitest::Test
  def test_parse_reads_from_stdin
    input = "CNSHA\nNLRTM\ncheapest\n"
    $stdin = StringIO.new(input)
    result = StdinInputParser.parse
    assert_equal ['CNSHA', 'NLRTM', 'cheapest'], result
  ensure
    $stdin = STDIN
  end
end

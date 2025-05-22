require_relative '../../../test_helper'
require_relative '../../../infrastructure/utils/input_parser'

class InputParserTest < Minitest::Test
  def test_parse_raises_not_implemented
    assert_raises(NotImplementedError) { InputParser.parse }
  end
end

require_relative '../../../test_helper'
require_relative '../../../infrastructure/utils/output_serializer'

class OutputSerializerTest < Minitest::Test
  def test_serialize_raises_not_implemented
    assert_raises(NotImplementedError) { OutputSerializer.serialize([], {}) }
  end
end

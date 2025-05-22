require_relative '../../../../test_helper'
require_relative '../../../../application/services/output_handler'

class OutputHandlerTest < Minitest::Test
  class DummySerializer
    def self.serialize(routes, rates_map)
      'serialized!'
    end
  end

  def setup
    @original_serializer = Object.const_get(:JsonResultSerializer) if Object.const_defined?(:JsonResultSerializer)
  end

  def test_serialize_and_print_json
    Object.send(:remove_const, :JsonResultSerializer) if Object.const_defined?(:JsonResultSerializer)
    Object.const_set(:JsonResultSerializer, DummySerializer)
    assert_output("serialized!\n") do
      OutputHandler.serialize_and_print([[Object.new]], {}, 'json')
    end
  end

  def test_serialize_and_print_empty
    Object.send(:remove_const, :JsonResultSerializer) if Object.const_defined?(:JsonResultSerializer)
    Object.const_set(:JsonResultSerializer, DummySerializer)
    assert_output("serialized!\n") do
      OutputHandler.serialize_and_print([], {}, 'json')
    end
  end

  def test_unsupported_format_xml
    assert_raises(RuntimeError) do
      OutputHandler.serialize_and_print([], {}, 'xml')
    end
  end
  
  def test_unsupported_format_csv
    error = assert_raises(RuntimeError) do
      OutputHandler.serialize_and_print([], {}, 'csv')
    end
    assert_equal 'CSV output not implemented yet', error.message
  end
  
  def test_unknown_format
    error = assert_raises(RuntimeError) do
      OutputHandler.serialize_and_print([], {}, 'unknown_format')
    end
    assert_equal 'Unknown output format: unknown_format', error.message
  end

  def teardown
    if Object.const_defined?(:JsonResultSerializer)
      Object.send(:remove_const, :JsonResultSerializer)
    end
    Object.const_set(:JsonResultSerializer, @original_serializer) if @original_serializer
  end
end

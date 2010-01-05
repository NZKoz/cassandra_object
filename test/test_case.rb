
class CassandraObjectTestCase < ActiveSupport::TestCase
  def teardown
    CassandraObject::Base.connection.clear_keyspace!
  end

  def mock_invoice
    Invoice.create :number=>Time.now.to_i*(rand(5)), :total=>Time.now.to_f
  end

  def connection
    CassandraObject::Base.connection
  end
  
  def assert_ordered(expected_object_order, actual_order, to_s_before_comparing = true)
    # don't use map! so we don't go changing user's arguments
    if to_s_before_comparing
      expected_object_order = expected_object_order.map(&:to_s) 
      actual_order = actual_order.map(&:to_s)
    end
    
    assert_equal Set.new(expected_object_order), Set.new(actual_order), "Collections weren't equal"
    actual_indexes = actual_order.map do |e|
      expected_object_order.index(e)
    end
    assert_equal expected_object_order, actual_order, "Collection was ordered incorrectly: #{actual_indexes.inspect}"
  end
end

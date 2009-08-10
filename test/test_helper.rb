
RAILS_MASTER_DIR = ENV['EDGE_RAILS'] || "/Users/michaelkoziarski/OpenSource/rails"

$: << File.join(RAILS_MASTER_DIR, 'activemodel', 'lib')
$: << File.join(RAILS_MASTER_DIR, 'activesupport', 'lib')

require 'active_model'
require 'active_support/all'
require 'cassandra_object/base'
require 'connection'

require 'test/unit'
require 'active_support/test_case'
require 'fixture_models'
require 'pp'
require 'Shoulda'

class CassandraObjectTestCase < ActiveSupport::TestCase
  def teardown
    #
  end

  def mock_invoice
    Invoice.create :number=>Time.now.to_i*(rand(5)), :total=>Time.now.to_f
  end

  def connection
    CassandraObject::Base.connection
  end
  
  def assert_ordered(expected_object_order, actual_order)
    assert_equal Set.new(expected_object_order), Set.new(actual_order), "Collections weren't equal"
    actual_indexes = actual_order.map do |e|
      expected_object_order.index(e)
    end
    assert_equal expected_object_order, actual_order, "Collection was ordered incorrectly: #{actual_indexes.inspect}"
  end
end

# class Cassandra
#   class UUID
#     def initialize_with_hax(*args)
#       initialize_without_hax(*args)
#       sleep 1
#     end
#     alias_method_chain :initialize, :hax
#   end
# end
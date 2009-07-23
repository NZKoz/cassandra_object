
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

class CassandraObjectTestCase < ActiveSupport::TestCase
  def teardown
    CassandraObject::Base.connection.clear_keyspace!
  end

  def mock_invoice
    Invoice.create :number=>Time.now.to_i*(rand(5)), :total=>Time.now.to_f
  end
end

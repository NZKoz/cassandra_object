
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

class CassandraObjectTestCase < ActiveSupport::TestCase
  def teardown
    CassandraObject::Base.connection.clear_keyspace!
  end
end

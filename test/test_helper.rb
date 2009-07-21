
RAILS_MASTER_DIR = ENV['EDGE_RAILS'] || "/Users/michaelkoziarski/OpenSource/rails"

$: << File.join(RAILS_MASTER_DIR, 'activemodel', 'lib')
$: << File.join(RAILS_MASTER_DIR, 'activesupport', 'lib')

require 'active_model'
require 'active_support/all'
require 'test/unit'
require 'active_support/test_case'
require 'cassandra_object/base'

CassandraObject::Base.establish_connection "CassandraObject"

# <Table Name="CassandraObject">
#   <ColumnFamily ColumnSort="Name" Name="Customers" />
#   <ColumnFamily ColumnType="Super" ColumnSort="Name" Name="CustomerRelationships" />
#   <ColumnFamily ColumnType="Super" ColumnSort="Name" Name="CustomerIndexes" />
#   <ColumnFamily ColumnSort="Name" Name="Invoices" />
#   <ColumnFamily ColumnType="Super" ColumnSort="Name" Name="InvoiceIndexes" />
#   <ColumnFamily ColumnType="Super" ColumnSort="Name" Name="InvoiceRelationships" />
#   <ColumnFamily ColumnSort="Name" Name="InvoicesByNumber" />
# </Table>


require 'fixture_models'

class CassandraObjectTestCase < ActiveSupport::TestCase

  def teardown
    CassandraObject::Base.connection.clear_keyspace!
  end
end
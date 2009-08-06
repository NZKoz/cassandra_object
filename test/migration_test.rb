require 'test_helper'

class MigrationTest < CassandraObjectTestCase
  test "a new invoice should have the right schema version" do
    i = mock_invoice
    assert_equal 2, i.schema_version
  end
  
  test " a new invoice should have an empty gst_number" do
    assert_equal nil, mock_invoice.gst_number
  end
  
  test "an old invoice should get fetched and updated" do
    key = Invoice.next_key.to_s
    connection.insert(Invoice.column_family, key, {"schema_version"=>"1", "number"=>"200", "total"=>"150.35"})
    
    invoice = Invoice.get(key)
    assert_equal 2, invoice.schema_version
    assert_equal 150.35, invoice.total
  end
end
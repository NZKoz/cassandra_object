require 'test_helper'

class CursorTest < CassandraObjectTestCase
  
  context "A Cursor working with a Super Column with mixed valid / invalid keys" do
    setup do
      @customer = Customer.create :first_name    => "Michael",
                                  :last_name     => "Koziarski",
                                  :date_of_birth => "1980-08-15"
                                  
      @old = mock_invoice.tap {|i| @customer.invoices << i }
      
      Customer.associations[:invoices].add(@customer, MockRecord.new("SomethingStupid"))
      
      @new = mock_invoice.tap {|i| @customer.invoices << i }
      
      assert_equal [@new.key, "SomethingStupid", @old.key],
                   association_keys_in_cassandra
      
    end
    
    context "starting at the beginning" do
      setup do
        @cursor = CassandraObject::Cursor.new(Invoice, Customer.associations[:invoices].column_family, @customer.key, "invoices")
      end

      should "leave values alone it doesn't scroll past" do
        assert_equal [@new], @cursor.find(1)

        assert_equal [@new.key, "SomethingStupid", @old.key],
                     association_keys_in_cassandra
      end

      should "clean up when it hits a missing record" do
        assert_equal [@new, @old], @cursor.find(2)
        assert_equal [@new.key, @old.key],
                     association_keys_in_cassandra
      end
    end
    
    context "starting after new" do
      setup do
        @cursor = CassandraObject::Cursor.new(Invoice, Customer.associations[:invoices].column_family, @customer.key, "invoices", :start_after=>@new.key)
      end
      
      should "clean up when it hits a missing record" do
        assert_equal [@old], @cursor.find(1)
        assert_equal [@new.key, @old.key],
                     association_keys_in_cassandra
      end
    end
    
  end
  
  
  def association_keys_in_cassandra
    Customer.connection.get(Customer.associations[:invoices].column_family, @customer.key, "invoices").keys
  end
end
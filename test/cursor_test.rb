require 'test_helper'

class CursorTest < CassandraObjectTestCase
  
  context "A Cursor working with a Super Column with mixed valid / invalid keys" do
    setup do
      @customer = Customer.create :first_name    => "Michael",
                                  :last_name     => "Koziarski",
                                  :date_of_birth => Date.parse("1980/08/15")
                                  
      @old = mock_invoice.tap {|i| @customer.invoices << i }
      
      @to_die = mock_invoice.tap {|i| @customer.invoices << i }
      
      @new = mock_invoice.tap {|i| @customer.invoices << i }
      
      assert_ordered [@new.key, @to_die.key, @old.key],
                   association_keys_in_cassandra
      
      Invoice.remove(@to_die.key)
    end
    
    context "starting at the beginning" do
      setup do
        @cursor = invoices_cursor(:reversed=>true)
      end

      should "leave values alone it doesn't scroll past" do
        assert_equal [@new], @cursor.find(1)

        assert_ordered [@new.key, @to_die.key, @old.key],
                     association_keys_in_cassandra
      end

      should "clean up when it hits a missing record" do
        assert_equal [@new, @old], @cursor.find(2)
        assert_ordered [@new.key, @old.key],
                     association_keys_in_cassandra
      end
    end
    
    context "starting at an offset" do
      setup do
        start_after = invoices_cursor(:reversed=>true).find(1).last_column_name
        @cursor = invoices_cursor(:start_after=>start_after, :reversed=>true)
      end
      
      should "clean up when it hits a missing record" do
        assert_equal [@old.key], @cursor.find(1).map(&:key), "Wasn't expecting #{@new.key.inspect}"
        assert_ordered [@new.key, @old.key],
                     association_keys_in_cassandra
      end
    end
    
  end
  
  
  def association_keys_in_cassandra
    res = Customer.connection.get(Customer.associations[:invoices].column_family, @customer.key.to_s, "invoices", :reversed=>true)
    res.values
  end
  
  def invoices_cursor(options = {})
    CassandraObject::Cursor.new(Invoice, Customer.associations[:invoices].column_family, @customer.key, "invoices", options)
  end
end
require 'test_helper'

class OneToManyAssociationsTest < CassandraObjectTestCase
  
  context "A customer with an invoice added to its invoice association" do 
    setup do
      @customer = Customer.create :first_name    => "Michael",
                                  :last_name     => "Koziarski",
                                  :date_of_birth => "1980-08-15"

      assert @customer.valid?, @customer.errors                            

      @invoice  = mock_invoice
      assert @invoice.valid?, @invoice.errors

      @customer.invoices << @invoice
    end
    
    should "have set the inverse" do
      assert_equal @customer, @invoice.customer
    end
    
    should "have also written to cassandra" do
      assert_equal @invoice, @customer.invoices.to_a.first
    end
    
    context "Simple Read-Repair" do
      setup do
        add_junk_key
        assert_equal ["SomethingStupid", @invoice.key], association_keys_in_cassandra
      end
    
      should "tidy up when fetching" do
        assert_equal [@invoice], @customer.invoices.all
        assert_equal [@invoice.key], association_keys_in_cassandra
      end
    end
  
    context "More complicated Read-Repair" do
      setup do
        # Now add a second legit invoice
        @second_invoice = mock_invoice
        @customer.invoices << @second_invoice

        add_junk_key

        @third_invoice = mock_invoice
        @customer.invoices << @third_invoice

        #

        assert_equal [@third_invoice.key,"SomethingStupid", @second_invoice.key,  @invoice.key],
                     association_keys_in_cassandra
      end
    
      should "return the last one when passed a limit of one, and not touch the keys" do
        assert_equal [@third_invoice], @customer.invoices.all(:limit=>1)
        assert_equal [@third_invoice.key,"SomethingStupid", @second_invoice.key,  @invoice.key],
                     association_keys_in_cassandra
      end
    
      should "return them all when passed a limit of 3, and clean up the keys" do
        assert_equal [@third_invoice, @second_invoice, @invoice], @customer.invoices.all(:limit=>3)
        assert_equal [@third_invoice.key, @second_invoice.key,  @invoice.key],
                     association_keys_in_cassandra
                   
      end
    
      should "return the first invoice when told to start after the second" do
        assert_equal [@invoice], @customer.invoices.all(:limit=>1, :start_after=>@second_invoice.key)
        assert_equal [@third_invoice.key,"SomethingStupid", @second_invoice.key,  @invoice.key],
                     association_keys_in_cassandra
      end
    end
  end

  def add_junk_key
    Customer.associations[:invoices].add(@customer, MockRecord.new("SomethingStupid"))
  end

  def association_keys_in_cassandra
    Customer.connection.get(Customer.associations[:invoices].column_family, @customer.key, "invoices").keys
  end
  
end
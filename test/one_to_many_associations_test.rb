require 'test_helper'

class OneToManyAssociationsTest < CassandraObjectTestCase
  def setup
    super
    @customer = Customer.create :first_name    => "Michael",
                                :last_name     => "Koziarski",
                                :date_of_birth => "1980-08-15"
    assert @customer.valid?, @customer.errors                            
    
    @invoice  = mock_invoice
    assert @invoice.valid?, @invoice.errors
    
    @customer.invoices << @invoice
  end
  
  test "has set the inverse" do
    assert_equal @customer, @invoice.customer
  end
  
  test "has written the key too" do
    assert_equal @invoice, @customer.invoices.to_a.first
  end
  
  test "handles read-repair" do
    add_junk_key

    assert_equal ["SomethingStupid", @invoice.key], association_keys_in_cassandra

    assert_equal [@invoice], @customer.invoices.to_a


    assert_equal [@invoice.key], association_keys_in_cassandra


  end

  test "read-repair with a limit" do
    
    # Now add a second legit invoice
    @second_invoice = mock_invoice
    @customer.invoices << @second_invoice

    add_junk_key

    @third_invoice = mock_invoice
    @customer.invoices << @third_invoice
    
    #
    
    assert_equal [@third_invoice.key,"SomethingStupid", @second_invoice.key,  @invoice.key],
                 association_keys_in_cassandra

    assert_equal [@third_invoice, @second_invoice], @customer.invoices.all(:limit=>2)
    assert_equal [@third_invoice, @second_invoice, @invoice], @customer.invoices.all(:limit=>2)
    
  end

  def add_junk_key
    invoices_association = Customer.associations[:invoices]
    invoices_association.add(@customer, MockRecord.new("SomethingStupid"))

  end

  def association_keys_in_cassandra
    Customer.connection.get(Customer.associations[:invoices].column_family, @customer.key, "invoices").keys
  end

  
end
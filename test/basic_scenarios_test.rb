require 'test_helper'

class BasicScenariosTest < CassandraObjectTestCase
  def setup
    super
    @customer = Customer.create :first_name    => "Michael",
                                :last_name     => "Koziarski",
                                :date_of_birth => "1980-08-15"
    @customer_key = @customer.key                            
    
    assert @customer.valid?
  end
  
  test "get on a non-existent key returns nil" do
    assert_nil Customer.get("THIS IS NOT A KEY")
  end

  test "a new object can be retrieved by key" do
    other_customer = Customer.get(@customer_key)

    assert_equal @customer, other_customer
    
    assert_equal "Michael", other_customer.first_name
    assert_equal "Koziarski", other_customer.last_name
    # FIXME
    # assert_equal Date.parse("1980-08-15"), other_customer.date_of_birth
  end
  
  test "date_of_birth is a date" do
    assert @customer.date_of_birth.is_a?(Date)
  end
  
  test "should have a schema version of 0" do
    assert_equal 0, @customer.schema_version
  end

  test "multiget" do
    custs = Customer.multi_get([@customer_key, "This is not a key either"])
    customer, nothing = custs.values

    assert_equal @customer, customer
    assert_nil nothing
  end

  test "creating a new record starts with the right version" do
    @invoice  = mock_invoice

    raw_result = Invoice.connection.get("Invoices", @invoice.key)
    assert_equal Invoice.current_schema_version, ActiveSupport::JSON.decode(raw_result["schema_version"])
  end
  
  context "destroying a customer with invoices" do
    setup do
      @invoice = mock_invoice
      @customer.invoices << @invoice
      
      @customer.destroy
    end
    
    should "Have removed the customer" do
      assert Customer.connection.get("Customers", @customer.key).empty?
    end
    
    should "Have removed the associations too" do
      assert_equal Hash.new, Customer.connection.get("CustomerRelationships", @customer.key)
    end
  end
end

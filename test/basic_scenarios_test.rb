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
  end
  
  test "date_of_birth is a date" do
    assert @customer.date_of_birth.is_a?(Date)
  end
end

require 'test_helper'

class DirtyTest < CassandraObjectTestCase
  def setup
    super

    @customer = Customer.create :first_name    => "Michael",
                                :last_name     => "Koziarski",
                                :date_of_birth => "1980/08/15"
    @customer_key = @customer.key
    assert @customer.valid?, @customer.errors.full_messages.to_sentence
  end

  test "a new object can be retrieved by key" do
    assert_equal "Michael", @customer.first_name
    assert !@customer.changed?

    @customer.first_name = "Josh"
    assert_equal "Josh", @customer.first_name

    assert @customer.changed?
    assert_equal Set.new([:first_name]), @customer.changed
    assert @customer.first_name_changed?
  end
end

require 'test_helper'

class DirtyTest < CassandraObjectTestCase
  def setup
    super

    @customer = Customer.create :first_name    => "Michael",
                                :last_name     => "Koziarski",
                                :date_of_birth => Date.parse("1980/08/15")
    @customer_key = @customer.key
    assert @customer.valid?, @customer.errors.full_messages.to_sentence
  end

  test "a new object can be retrieved by key" do
    assert_equal "Michael", @customer.first_name
    assert !@customer.changed?
    assert_equal [], @customer.changed
    assert_equal({}, @customer.changes)

    @customer.first_name = "Josh"
    assert_equal "Josh", @customer.first_name

    assert @customer.changed?
    assert_equal ["first_name"], @customer.changed
    assert_equal({"first_name" => ["Michael", "Josh"]}, @customer.changes)

    assert @customer.first_name_changed?
    assert_equal ["Michael", "Josh"], @customer.first_name_change
    assert_equal "Michael", @customer.first_name_was

    @customer.reset_first_name!
    assert_equal "Michael", @customer.first_name
  end
end

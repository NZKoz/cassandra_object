require 'test_helper'

class BasicScenariosTest < CassandraObjectTestCase
  def setup
    super
    @customer = Customer.create :first_name    => "Michael",
                                :last_name     => "Koziarski",
                                :date_of_birth => Date.parse("1980/08/15")
    @customer_key = @customer.key.to_s                          

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
    assert_equal Date.parse("1980-08-15"), other_customer.date_of_birth
  end
  
  test "a new object is included in Model.all" do
    assert Customer.all.include?(@customer)
  end

  test "date_of_birth is a date" do
    assert @customer.date_of_birth.is_a?(Date)
  end

  test "should not let you assign junk to a date column" do
    assert_raise(ArgumentError) do
      @customer.date_of_birth = 24.5
    end
  end

  test "should return nil for attributes without a value" do
    assert_nil @customer.preferences
  end

  test "should let a user set a Hash valued attribute" do
    val = {"a"=>"b"}
    @customer.preferences = val
    assert_equal val, @customer.preferences
    @customer.save
    
    other_customer = Customer.get(@customer_key)
    assert_equal val, other_customer.preferences
  end

  test "should validate strings passed to a typed column" do
    assert_raises(ArgumentError){
      @customer.date_of_birth = "35345908"
    }
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

    raw_result = Invoice.connection.get("Invoices", @invoice.key.to_s)
    assert_equal Invoice.current_schema_version, ActiveSupport::JSON.decode(raw_result["schema_version"])
  end

  test "to_param works" do
    invoice = mock_invoice
    param = invoice.to_param
    assert_match /[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}/, param
    assert_equal invoice.key, Invoice.parse_key(param)
  end

  test "setting a column_family" do
    class Foo < CassandraObject::Base
      self.column_family = 'Bar'
    end
    assert_equal 'Bar', Foo.column_family
  end

  context "destroying a customer with invoices" do
    setup do
      @invoice = mock_invoice
      @customer.invoices << @invoice
      
      @customer.destroy
    end
    
    should "Have removed the customer" do
      assert Customer.connection.get("Customers", @customer.key.to_s).empty?
    end
    
    should "Have removed the associations too" do
      assert_equal Hash.new, Customer.connection.get("CustomerRelationships", @customer.key.to_s)
    end
  end

  context "An object with a natural key" do
    setup do
      @payment = Payment.new :reference_number => "12345",
                             :amount           => 1001
      @payment.save!
    end

    should "create a natural key based on that attr" do
      assert_equal "12345", @payment.key.to_s
    end

    should "have a key equal to another object with that key" do
      p = Payment.new(:reference_number => "12345",
                      :amount           => 1001)
      p.save

      assert_equal @payment.key, p.key
    end
  end

  context "Model with no attributes" do
    setup do
      class Empty < CassandraObject::Base
      end
    end

    should "work" do
      e = Empty.new
    end
  end

  context "A model that allows nils" do
    setup do
      class Nilable < CassandraObject::Base
        attribute :user_id, :type => Integer, :allow_nil => true
      end
    end

    should "should be valid with a nil" do
      n = Nilable.new
      assert n.valid?
    end
  end

  context "A janky custom key factory" do
    setup do 
      class JankyKeys
        def next_key(object)
          nil
        end
      end
      class JankyObject < CassandraObject::Base
        key JankyKeys.new
      end
      @object = JankyObject.new
    end

    should "raise an error on nil key" do
      assert_raises(RuntimeError) do
        @object.save
      end
    end
  end

  test "updating columns" do
    appt = Appointment.new(:start_time => Time.now, :title => 'emergency meeting')
    appt.save!
    appt = Appointment.get(appt.key)
    appt.start_time = Time.now + 1.hour
    appt.end_time = Time.now.utc +  5.hours
    appt.save!
    assert appt.reload.end_time.is_a?(ActiveSupport::TimeWithZone)
  end
  
  test "Saving a class with custom attributes uses the custom converter" do
    @customer.custom_storage = "hello"
    @customer.save

    raw_result = Customer.connection.get("Customers", @customer.key.to_s)
    
    assert_equal "olleh", raw_result["custom_storage"]
    assert_equal "hello", @customer.reload.custom_storage
    
  end

  context "setting valid consistency levels" do
    setup do
      class Senate < CassandraObject::Base
        consistency_levels :write => :quorum, :read => :quorum
      end
    end

    should "should have the settings" do
      assert_equal :quorum, Senate.write_consistency
      assert_equal :quorum, Senate.read_consistency
    end
  end

  context "setting invalid consistency levels" do
    context "invalid write consistency" do
      should "raise an error" do
        assert_raises(ArgumentError) do
          class BadWriter < CassandraObject::Base
            consistency_levels :write => :foo, :read => :quorum
          end
        end
      end
    end

    context "invalid read consistency" do
      should "raise an error" do
        assert_raises(ArgumentError) do
          class BadReader < CassandraObject::Base
            consistency_levels :write => :quorum, :read => :foo
          end
        end
      end
    end
  end

  test "ignoring columns we don't know about" do
    # if there's a column in the row that's not configured as an attribute, it should be ignored with no errors

    payment = Payment.new(:reference_number => 'abc123', :amount => 26)
    payment.save

    Payment.connection.insert(Payment.column_family, payment.key.to_s, {"bogus" => 'very bogus', "schema_version" => payment.schema_version.to_s}, :consistency => Payment.send(:write_consistency_for_thrift))

    assert_nothing_raised do
      Payment.get(payment.key)
    end
  end
end

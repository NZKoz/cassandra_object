require 'test_helper'

class AttributeHandlersTest < CassandraObjectTestCase
  include CassandraObject::AttributeHandlers
  
  context "The String attribute handler" do
    setup do
      @handler = StringHandler.new
    end
    
    should "pass strings through unchanged" do
      value = "Hello"
      assert_equal value, @handler.parse(value)
      assert_equal value, @handler.serialize(value)
    end
    
    should "handle nil" do
      assert_equal nil, @handler.parse(nil)
      assert_equal nil, @handler.serialize(nil)
    end
  end
  
  context "The Date attribute handler" do
    setup do
      @handler = DateHandler.new
    end
    
    should "parse values correctly" do
      assert_equal Date.new(2009, 12, 31), @handler.parse("2009-12-31")
    end
    
    should "serialize values correctly" do
      assert_equal "2009-12-31", @handler.serialize(Date.new(2009, 12, 31))
    end

    should "handle nil" do
      assert_equal nil, @handler.parse(nil)
      assert_equal nil, @handler.serialize(nil)
    end
  end
  
  context "The Integer Attribute Handler" do
    setup do
      @handler = IntegerHandler.new
    end
    
    should "parse values correctly" do
      assert_equal 25, @handler.parse("25")
      assert_equal -25, @handler.parse("-25")
    end
    
    should "serialize values correctly" do
      assert_equal "25", @handler.serialize(25)
      assert_equal "-25", @handler.serialize(-25)
    end

    should "handle nil" do
      assert_equal nil, @handler.parse(nil)
      assert_equal nil, @handler.serialize(nil)
    end
  end
  
  context "The Float Attribute Handler" do
    setup do
      @handler = FloatHandler.new
    end
    
    should "parse values correctly" do
      assert_equal 25.5, @handler.parse("25.5")
      assert_equal -25.5, @handler.parse("-25.5")
    end
    
    should "serialize values correctly" do
      assert_equal "25.5", @handler.serialize(25.5)
      assert_equal "-25.5", @handler.serialize(-25.5)
    end

    should "handle nil" do
      assert_equal nil, @handler.parse(nil)
      assert_equal nil, @handler.serialize(nil)
    end
  end
  
  context "The Time AttributeHandler" do
    setup do
      @handler = TimeHandler.new
    end
    should "parse values correctly" do
      assert_equal Time.utc(2009, 12, 31, 1, 35, 15), @handler.parse("2009-12-31T01:35:15Z")
    end
    
    should "serialize values correctly" do
      assert_equal "2009-12-31T01:35:15Z", @handler.serialize(Time.utc(2009, 12, 31, 1, 35, 15))
    end

    should "handle nil" do
      assert_equal nil, @handler.parse(nil)
      assert_equal nil, @handler.serialize(nil)
    end
  end
  
  context "The TimeWithZone AttributeHandler" do
    setup do
      @handler  = TimeWithZoneHandler.new
      @utc_time = Time.utc(2009, 12, 31, 1, 35, 15) 
      @tz_time  = @utc_time.in_time_zone("Wellington")
    end
    should "parse values correctly" do
      assert_equal @tz_time, @handler.parse("2009-12-31T01:35:15Z")
    end
    
    should "serialize values correctly" do
      assert_equal "2009-12-31T01:35:15Z", @handler.serialize(@tz_time)
    end

    should "handle nil" do
      assert_equal nil, @handler.parse(nil)
      assert_equal nil, @handler.serialize(nil)
    end
  end

  context "The Object AttributeHandler" do
    setup do
      @handler = ObjectHandler.new
      @hash    = {'wtf'=>'hax'}
    end
    
    should "parse values correctly" do
      assert_equal @hash, @handler.parse("{'wtf' : 'hax'}")
    end
    
    should "serialize values correctly" do
      assert_equal %({"wtf":"hax"}), @handler.serialize(@hash)
    end

    should "handle nil" do
      assert_equal nil, @handler.parse(nil)
      assert_equal nil, @handler.serialize(nil)
    end
  end
  
  context "A model with a custom attribute handler" do
    setup do
      @customer = Customer.create :first_name     => "Michael",
                                  :last_name      => "Koziarski",
                                  :date_of_birth  => "1980-08-15",
                                  :custom_storage => "Backwards!!"
    end
    
    should "return the value when reloaded" do
      @customer = Customer.get(@customer.key)
      assert_equal "Backwards!!", @customer.custom_storage
    end
    
    should "Have stored it in reverse" do
      raw_result = Customer.connection.get("Customers", @customer.key.to_s)
      assert_equal "!!sdrawkcaB", raw_result["custom_storage"]
    end
  end
end
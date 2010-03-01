require 'test_helper'

class TypesTest < CassandraObjectTestCase
  context "IntegerType" do
    context "encode" do

      should "return an int with no errors" do
        assert_nothing_raised {
          i = 12
          assert_equal i.to_s, CassandraObject::IntegerType.encode(i)
        }
      end

      should "raises an error on non-Integer input" do
        assert_raises(ArgumentError) { CassandraObject::IntegerType::encode('')}
      end

      should "work with Bignums" do
        assert_nothing_raised {
          i = 2**32
          assert_equal i.to_s, CassandraObject::IntegerType.encode(i)
        }
      end

      should "work with Fixnums" do
        assert_nothing_raised {
          i = 2**16
          assert_equal Fixnum, i.class
          assert_equal i.to_s, CassandraObject::IntegerType.encode(i)
        }
      end
    end

    context "decode" do
      should "work with an int" do
        assert_nothing_raised {
          assert_equal 12, CassandraObject::IntegerType.decode('12')
        }
      end

      should "work with Bignums" do
        assert_nothing_raised {
          assert_equal 2**32, CassandraObject::IntegerType.decode((2**32).to_s)
        }
      end

      should "reject trash" do
        assert_raises(ArgumentError) {
          CassandraObject::IntegerType.decode('asdf')
        }
      end

      should "work on a negative number" do
        assert_equal -1, CassandraObject::IntegerType.decode('-1')
      end

      should "work with a leading +" do
        assert_equal 1, CassandraObject::IntegerType.decode('+1')
      end
    end
  end

  context "FloatType" do
    context "encode" do
      should "should reject an Integer" do
        assert_raises(ArgumentError) {
          CassandraObject::FloatType.encode(1)
        }
      end

      should "reject a string" do
        assert_raises(ArgumentError) {
          CassandraObject::FloatType.encode('asdf')
        }
      end

      should "return a string" do
        assert_equal '1.0', CassandraObject::FloatType.encode(1.0)
      end

      should "accept a negative number" do
        assert_equal '-1.0', CassandraObject::FloatType.encode(-1.0)
      end
    end

    context "decode" do
      should "reject a non-float" do
        assert_raises(ArgumentError) {
          CassandraObject::FloatType.decode('asdf')
        }
      end

      should "work on a float" do
        assert_equal 1.2, CassandraObject::FloatType.decode('1.2')
      end

      should "work on a negative number" do
        assert_equal -1.2, CassandraObject::FloatType.decode('-1.2')
      end

      should "work with a leading +" do
        assert_equal 1.2, CassandraObject::FloatType.decode('+1.2')
      end
    end
  end

  context "DateType" do
    context "encode" do
      should "accept a valid Date object" do
        assert_nothing_raised {
          CassandraObject::DateType.encode(Date.today)
        }
      end

      should "reject a String, even if it looks like a date" do
        assert_raises(ArgumentError) { CassandraObject::DateType.encode('2009-10-31') }
      end

      should "reject an Integer" do
        assert_raises(ArgumentError) { CassandraObject::DateType.encode(12) }
      end

      should "return a properly formatted string" do
        str = '2009-10-31'
        date = Date.strptime(str)
        assert_equal str, CassandraObject::DateType.encode(date)
      end
    end

    context "decode" do
      should "work on a properly formatted string" do
        s = '2009-10-31'
        assert_equal Date.strptime(s), CassandraObject::DateType.decode(s)
      end

      should "reject a badly formatted string" do
        assert_raises(ArgumentError) {
          CassandraObject::DateType.decode('asdf')
        }
      end
    end
  end

  context "TimeType" do
    context "#encode" do
      should "accept a Time" do
        assert_nothing_raised {CassandraObject::TimeType.encode(Time.now)}
      end

      should "return a properly formated string for a legit time" do
        t = Time.now
        formatted = t.xmlschema(6)
        assert_equal(formatted, CassandraObject::TimeType.encode(t))
      end

      should "reject things other than Time" do
        assert_raises(ArgumentError) {
          CassandraObject::TimeType.encode(1)
        }
        assert_raises(ArgumentError) {
          CassandraObject::TimeType.encode('asdf')
        }
      end
    end

    context "#decode" do
      should "parse a valid string and return a Time (with timezone)" do
        time = Time.xmlschema(str = "2009-11-05T13:24:07-08:00")
        assert_nothing_raised {
          assert_equal time, CassandraObject::TimeType.decode(str)
        }
      end

      should "parse a valid string and return a Time (with UTC)" do
        time = Time.xmlschema(str = "2009-11-05T13:24:07Z")
        assert_nothing_raised {
          assert_equal time, CassandraObject::TimeType.decode(str)
        }
      end
    end
  end

  context "HashType" do
    context "encode" do
      should "handle an empty Hash" do
        assert_nothing_raised {
          assert_equal({}.to_json, CassandraObject::HashType.encode({}))
        }
      end

      should "handle string keys" do
        assert_nothing_raised {
          h = {'foo' => 'bar'}
          assert_equal(h.to_json, CassandraObject::HashType.encode(h))
        }
      end

      should "handle symbol keys" do
        assert_nothing_raised {
          h = {:foo => 'bar'}
          assert_equal(h.to_json, CassandraObject::HashType.encode(h))
        }
      end
    end
  end

  context "BooleanType" do
    context "encode" do
      should "handle true" do
        assert_nothing_raised {
          assert_equal '1', CassandraObject::BooleanType.encode(true)
        }
      end

      should "handle false" do
        assert_nothing_raised {
          assert_equal '0', CassandraObject::BooleanType.encode(false)
        }
      end

      should "handle nil" do
        assert_nothing_raised {
          assert_equal '0', CassandraObject::BooleanType.encode(nil)
        }
      end

      should "not handle normal objects" do
        assert_raises(ArgumentError) {
          assert_equal '1', CassandraObject::BooleanType.encode(Object.new)
        }
      end
    end

    context "decode" do
      should "handle true" do
        assert_nothing_raised {
          assert_equal true, CassandraObject::BooleanType.decode('1')
        }
      end

      should "handle false" do
        assert_nothing_raised {
          assert_equal false, CassandraObject::BooleanType.decode('0')
        }
      end

      should "handle bad data as false" do
        assert_equal false, CassandraObject::BooleanType.decode('')
      end
    end
  end
end

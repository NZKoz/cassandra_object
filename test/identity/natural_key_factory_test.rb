require 'test_helper'

module Identity
  class NaturalKeyFactoryTest < CassandraObjectTestCase
    context "With one attribute" do
      setup do
        @key_factory = CassandraObject::Identity::NaturalKeyFactory.new :attributes => :name
      end

      should "have a key whose string and param value is the value of that attribute" do
        @key = @key_factory.next_key(stub(:name => "james"))

        assert_equal "james", @key.to_s
        assert_equal "james", @key.to_param
      end

      should "parse to a key from a param value" do
        @key = @key_factory.parse("james")

        assert_equal "james", @key.to_s
        assert_equal "james", @key.to_param
      end

      should "create a key from a value" do
        @key = @key_factory.create("james")

        assert_equal "james", @key.to_s
        assert_equal "james", @key.to_param
      end
    end
  end
end


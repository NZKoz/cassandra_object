require 'test_helper'

module Identity
  class NaturalKeyFactoryTest < CassandraObjectTestCase
    context "With one attribute" do
      setup do
        @key_factory = CassandraObject::Identity::NaturalKeyFactory.new :attributes => :name
        @james = Person.new("name" => "james")
      end

      should "have a key whose string and param value is the value of that attribute" do
        @key = @key_factory.next_key(@james)

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

    context "With multiple attributes" do
      setup do
        @key_factory = CassandraObject::Identity::NaturalKeyFactory.new :attributes => [:name, :age]
        @james = Person.new("name" => "james", "age" => 23)
      end

      should "create a key whose string value is the two values, joined with a separator" do
        key = @key_factory.next_key(@james)
        
        assert_equal "james-23", key.to_s
        assert_equal "james-23", key.to_param
      end

      should "parse the key" do
        key = @key_factory.parse("james-23")
        
        assert_equal "james-23", key.to_s
        assert_equal "james-23", key.to_param
      end

      should "create the key" do
        key = @key_factory.create("james-23")
        
        assert_equal "james-23", key.to_s
        assert_equal "james-23", key.to_param
      end
    end

    context "With a custom separator" do
      setup do
        @key_factory = CassandraObject::Identity::NaturalKeyFactory.new :attributes => [:name, :age],
                                                                        :separator  => "#"
        @james = Person.new("name" => "james", "age" => 23)
      end

      should "join the attributes with the custom separator" do
        key = @key_factory.next_key(@james)

        assert_equal "james#23", key.to_s
      end
    end

    context "Natural keys" do
      setup do
        @james         = CassandraObject::Identity::NaturalKeyFactory::NaturalKey.new("james")
        @another_james = CassandraObject::Identity::NaturalKeyFactory::NaturalKey.new("james")
        @joe           = CassandraObject::Identity::NaturalKeyFactory::NaturalKey.new("joe")
      end

      should "be equal, if their values are equal" do
        assert @james == @another_james
        assert @james.eql?(@another_james)
      end

      should "not be equal if their values are different" do
        assert @james != @joe
        assert !@james.eql?(@joe)
      end
    end
  end
end


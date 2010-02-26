# The filename is so that this test gets loaded last, since it depends on all the other tests.
#  Suggestions of less janky ways to do this would be appreciated. -rk

require 'test_helper'

class MockTest < CassandraObjectTestCase
  context CassandraObject::Base do
    should "respond to use_mock!" do
      assert CassandraObject::Base.respond_to?(:use_mock!)
    end
    context "use_mock!" do
      should "set the connection_class" do
        CassandraObject::Base.use_mock!
        assert_equal Cassandra::Mock, CassandraObject::Base.connection_class
        CassandraObject::Base.use_mock!(false)
      end
    end
  end
end

module MockTestMixin
  def setup
    CassandraObject::Base.use_mock!
    super
  end

  def teardown
    CassandraObject::Base.use_mock!(false)
  end
end

%w[BasicScenarios Cursor Dirty Index Migration OneToManyAssociations Time Types Validation].each do |test|
  klass = Class.new(Kernel.const_get(test + 'Test'))
  klass.send(:include, MockTestMixin)
  Kernel.const_set(test + 'WithMockTest', klass)
end

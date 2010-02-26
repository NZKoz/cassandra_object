require 'cassandra/mock'
module CassandraObject
  module Mocking
    extend ActiveSupport::Concern
    module ClassMethods
      def use_mock!(really=true)
        if really
          self.connection_class = Cassandra::Mock
        else
          self.connection_class = Cassandra
        end
      end
    end
  end
end

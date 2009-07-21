require 'cassandra_client'
require 'set'
require 'cassandra_object/attributes'
require 'cassandra_object/persistence'
require 'cassandra_object/validation'
require 'cassandra_object/callbacks'
require 'cassandra_object/identity'
require 'cassandra_object/indexes'
require 'cassandra_object/serialization'
require 'cassandra_object/associations'
require 'cassandra_object/migrations'

module CassandraObject
  class Base
    
    class_inheritable_accessor :connection
    module ConnectionManagement
      def establish_connection(*args)
        self.connection = CassandraClient.new(*args)
      end
    end
    extend ConnectionManagement
    
    module Naming
      def column_family
        name.pluralize
      end
    end
    extend Naming
    
    include Callbacks
    include Identity
    include Attributes
    include Persistence
    include Indexes
    
    

    include Validation
    include Associations
    



    attr_reader :key, :attributes

    include Serialization
    include Migrations


    def initialize(attributes={})
      @key = attributes.delete(:key)
      @new_record = true
      @changed_attribute_names = Set.new
      @attributes = {}.with_indifferent_access
      self.attributes = attributes
    end
  end
end
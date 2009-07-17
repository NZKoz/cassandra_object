require 'cassandra_client'
require 'set'
require 'cassandra_object/attributes'
require 'cassandra_object/persistence'
require 'cassandra_object/validation'
require 'cassandra_object/callbacks'
require 'cassandra_object/identity'
require 'cassandra_object/indexes'
require 'cassandra_object/serialization'

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
    include Serialization
    
    

    include Validation
    
    



    attr_reader :id, :attributes
    
    def initialize(id, attributes)
      @id = id
      @changed_attribute_names = Set.new
      @attributes = {}.with_indifferent_access
      self.attributes=attributes
      @changed_attribute_names = Set.new
    end
        
    
    def new_record?
      @id.nil?
    end
    
  end
end
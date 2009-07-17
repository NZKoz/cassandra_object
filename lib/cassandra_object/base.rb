require 'cassandra_client'
require 'set'
require 'cassandra_object/attributes'

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
    

    include Attributes
    
    module Fetching
      def get(id)
        # Can't use constructor for both 'fetch' and 'new'
        # take approach from AR.
        new(id, connection.get(column_family, id))
      end

      def all(keyrange = ''..'', options = {})
        connection.get_key_range(column_family, keyrange, options[:limit] || 100).map {|key| get(key) }
      end
    end
    extend Fetching

    module Writing
      def create(attributes)
        new(nil, attributes).save
      end

      def write(id, attributes)
        unless id
          id = next_id
        end
        connection.insert(column_family, id, attributes.stringify_keys)
        return id
      end
    end
    extend Writing
    
    
    module Keys
      def key(name = :uuid, &blk)
        if block_given?
          @key = blk
        else
          @key = case name
          when :uuid
            lambda { [Time.now.utc.strftime("%Y%m%d%H%M%S"), Process.pid, rand(1024)] * "" }
          end
        end
      end
      
      def next_id
        @key.call
      end
    end
    extend Keys
    
    
    
    class_inheritable_accessor :indexes
    class UniqueIndex
      def initialize(attribute_name, model_class)
        @attribute_name = attribute_name
        @model_class    = model_class
      end
      
      def find(attribute_value)
        # first find the id value
        id = @model_class.connection.get(column_family, attribute_value.to_s, 'id')
        # then pass to get
        @model_class.get(id)
      end
      
      def write(record)
        @model_class.connection.insert(column_family, record.send(@attribute_name).to_s, {'id'=>record.id})
      end
      
      def column_family
        @model_class.column_family + "By" + @attribute_name.to_s.camelize 
      end
    end
    
    class Index
      def initialize(attribute_name, model_class)
        @attribute_name = attribute_name
        @model_class    = model_class
      end
      
      def find(attribute_value)
        # first find the id values
        ids = @model_class.connection.get(column_family, attribute_value.to_s, @attribute_name)
        # then pass to get
        ids.keys.map {|id| @model_class.get(id) }
      end
      
      def write(record)
        @model_class.connection.insert(column_family, record.send(@attribute_name).to_s, {@attribute_name.to_s=>{record.id=>nil}})
      end
      
      def column_family
        @model_class.to_s + "Indexes"
      end
    end
    
    module Indexes
      def index(attribute_name, options = {})
        self.indexes ||= {}.with_indifferent_access
        if options[:unique]
          self.indexes[attribute_name] = UniqueIndex.new(attribute_name, self)
          class_eval <<-eom
            def self.find_by_#{attribute_name}(value)
              indexes[:#{attribute_name}].find(value)
            end
            
            after_save do |record|
              self.indexes[:#{attribute_name}].write(record)
            end
              
          eom
        else
          self.indexes[attribute_name] = Index.new(attribute_name, self)
          class_eval <<-eom
            def self.find_all_by_#{attribute_name}(value)
              self.indexes[:#{attribute_name}].find(value)
            end
            
            after_save do |record|
              record.class.indexes[:#{attribute_name}].write(record)
            end
              
          eom
        end
      end
    end
    extend Indexes
    
    

    include ActiveSupport::Callbacks
    define_callbacks :before_save, :after_save, :before_create, :after_create
    include ActiveModel::Validations
    define_callbacks :before_validation



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
    
    def save
      run_callbacks :before_validation
      if valid?
        if was_new_record = new_record?
          run_callbacks :before_create
        end
        run_callbacks :before_save
        @id ||= self.class.write(id, changed_attributes)
        run_callbacks :after_save
        run_callbacks :after_create if was_new_record
      end
      self
    end
  end
end
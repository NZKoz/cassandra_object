module CassandraObject
  module Indexes
    extend ActiveSupport::Concern
    
    included do
      class_inheritable_accessor :indexes
    end
    
    class UniqueIndex
      def initialize(attribute_name, model_class)
        @attribute_name = attribute_name
        @model_class    = model_class
      end
      
      def find(attribute_value)
        # first find the key value
        key = @model_class.connection.get(column_family, attribute_value.to_s, 'key')
        # then pass to get
        if key
          @model_class.get(key.to_s)
        else
          nil
        end
      end
      
      def write(record)
        @model_class.connection.insert(column_family, record.send(@attribute_name).to_s, {'key'=>record.key})
      end
      
      def remove(record)
        @model_class.connection.remove(column_family, record.send(@attribute_name).to_s)
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
      
      def find(attribute_value, options = {})
        # first find the keys
        res = @model_class.connection.get(column_family, attribute_value.to_s, @attribute_name.to_s, nil, options[:limit] || 100)

        # then pass to get
        @model_class.multi_get(res.keys).values
      end
      
      def write(record)
        @model_class.connection.insert(column_family, record.send(@attribute_name).to_s, {@attribute_name.to_s=>{record.key=>nil}})
      end
      
      def remove(record)
        @model_class.connection.remove(column_family, record.send(@attribute_name).to_s, @attribute_name.to_s, record.key)
      end
      
      def column_family
        @model_class.column_family + "By" + @attribute_name.to_s.camelize 
      end
    end
    
    module ClassMethods
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
              
            after_destroy do |record|
              record.class.indexes[:#{attribute_name}].remove(record)
            end
          eom
        else
          self.indexes[attribute_name] = Index.new(attribute_name, self)
          class_eval <<-eom
            def self.find_all_by_#{attribute_name}(value, options = {})
              self.indexes[:#{attribute_name}].find(value, options)
            end
            
            after_save do |record|
              record.class.indexes[:#{attribute_name}].write(record)
            end
              
            after_destroy do |record|
              record.class.indexes[:#{attribute_name}].remove(record)
            end
          eom
        end
      end
    end
  end
end
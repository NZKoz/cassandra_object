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
  end
end
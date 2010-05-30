module CassandraObject
  module Indexes
    extend ActiveSupport::Concern
    
    included do
      class_inheritable_accessor :indexes
    end
    
    class UniqueIndex
      def initialize(attribute_name, model_class, options)
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
          @model_class.connection.remove(column_family, attribute_value.to_s)
          nil
        end
      end
      
      def write(record)
        @model_class.connection.insert(column_family, record.send(@attribute_name).to_s, {'key'=>record.key.to_s})
      end
      
      def remove(record)
        @model_class.connection.remove(column_family, record.send(@attribute_name).to_s)
      end
      
      def column_family
        @model_class.column_family + "By" + @attribute_name.to_s.camelize 
      end
      
      def column_family_configuration
        {:Name=>column_family, :CompareWith=>"UTF8Type"}
      end
    end
    
    class Index
      def initialize(attribute_name, model_class, options)
        @attribute_name = attribute_name
        @model_class    = model_class
        @reversed       = options[:reversed]
      end
      
      def find(attribute_value, options = {})
        cursor = CassandraObject::Cursor.new(@model_class, column_family, attribute_value.to_s, @attribute_name.to_s, :start_after=>options[:start_after], :reversed=>@reversed)
        cursor.validator do |object|
          object.send(@attribute_name) == attribute_value
        end
        cursor.find(options[:limit] || 100)
      end
      
      def write(record)
        @model_class.connection.insert(column_family, record.send(@attribute_name).to_s, {@attribute_name.to_s=>{new_key=>record.key.to_s}})
      end
      
      def remove(record)
      end
      
      def column_family
        @model_class.column_family + "By" + @attribute_name.to_s.camelize 
      end
      
      def new_key
        SimpleUUID::UUID.new
      end
      
      def column_family_configuration
        {:Name=>column_family, :CompareWith=>"UTF8Type", :ColumnType=>"Super", :CompareSubcolumnsWith=>"TimeUUIDType"}
      end
      
    end
    
    module ClassMethods
      def column_family_configuration
        if indexes
          super + indexes.values.map(&:column_family_configuration)
        else
          super
        end
      end
      
      def index(attribute_name, options = {})
        self.indexes ||= {}.with_indifferent_access
        if options.delete(:unique)
          self.indexes[attribute_name] = UniqueIndex.new(attribute_name, self, options)
          class_eval <<-eom
            def self.find_by_#{attribute_name}(value)
              indexes[:#{attribute_name}].find(value)
            end
            
            after_save do |record|
              self.indexes[:#{attribute_name}].write(record)
              true
            end
              
            after_destroy do |record|
              record.class.indexes[:#{attribute_name}].remove(record)
              true
            end
          eom
        else
          self.indexes[attribute_name] = Index.new(attribute_name, self, options)
          class_eval <<-eom
            def self.find_all_by_#{attribute_name}(value, options = {})
              self.indexes[:#{attribute_name}].find(value, options)
            end
            
            after_save do |record|
              record.class.indexes[:#{attribute_name}].write(record)
              true
            end
              
            after_destroy do |record|
              record.class.indexes[:#{attribute_name}].remove(record)
              true
            end
          eom
        end
      end
    end
  end
end
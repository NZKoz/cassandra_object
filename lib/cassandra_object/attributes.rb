module CassandraObject
  class Attribute

    attr_reader :name, :converter, :expected_type
    def initialize(name, owner_class, converter, expected_type, options)
      @name          = name.to_s
      @owner_class   = owner_class
      @converter     = converter
      @expected_type = expected_type
      @options       = options
    end

    def check_value!(value)
      converter.encode(value) unless value.nil? && @options[:allow_nil]
      value
    end

    def define_methods!
      @owner_class.define_attribute_methods(true)
    end
  end

  module Attributes
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    module ClassMethods
      def attribute(name, options)
        
        unless type_mapping = attribute_types[options[:type]]
          type_mapping =  { :expected_type => options[:type], 
                            :converter => options[:converter] }.with_indifferent_access
        end
        
        new_attr = Attribute.new(name, self, type_mapping[:converter], type_mapping[:expected_type], options)
        write_inheritable_hash(:model_attributes, {name => new_attr}.with_indifferent_access)
        new_attr.define_methods!
      end

      def define_attribute_methods(force = false)
        return unless model_attributes
        undefine_attribute_methods if force
        super(model_attributes.keys)
      end
      
      def register_attribute_type(name, expected_type, converter)
        attribute_types[name] = { :expected_type => expected_type, :converter => converter }.with_indifferent_access
      end
    end

    included do
      class_inheritable_hash :model_attributes
      attribute_method_suffix("", "=")
      
      cattr_accessor :attribute_types
      self.attribute_types = {}.with_indifferent_access
    end

    module InstanceMethods
      def write_attribute(name, value)
        if ma = self.class.model_attributes[name]
          @attributes[name.to_s] = ma.check_value!(value)
        else
          raise NoMethodError, "Unknown attribute #{name.inspect}"
        end
      end

      def read_attribute(name)
        @attributes[name.to_s]
      end

      def attributes=(attributes)
        attributes.each do |(name, value)|
          send("#{name}=", value)
        end
      end

      protected
        def attribute_method?(name)
          !!model_attributes[name.to_sym]
        end

      private
        def attribute(name)
          read_attribute(name.to_sym)
        end

        def attribute=(name, value)
          write_attribute(name.to_sym, value)
        end
    end
  end
end

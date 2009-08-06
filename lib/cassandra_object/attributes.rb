module CassandraObject
  class Attribute
    FORMATS = {}
    FORMATS[Date] = /^\d{4}\/\d{2}\/\d{2}$/
    FORMATS[Integer] = /^-?\d+$/
    FORMATS[Float]   = /^-?\d*\.\d*$/
    
    CONVERTERS = {}
    CONVERTERS[Date] = Proc.new do |str|
      Date.strptime(str, "%Y/%m/%d")
    end
    
    CONVERTERS[Integer] = Proc.new do |str|
      Integer(str)
    end
    
    CONVERTERS[Float] = Proc.new do |str|
      Float(str)
    end
    
    attr_reader :name
    def initialize(name, owner_class, options)
      @name = name.to_s
      @owner_class = owner_class
      @options = options
      
      append_validations!
      define_methods!
    end
  
    # I think this should live somewhere in Amo
    def check_value!(value)
      # Allow nil and Strings to fall back on the validations for typecasting
      # Everything else gets checked with is_a?
      if value.nil?
        nil
      elsif value.is_a?(String)
        value
      elsif value.is_a?(expected_type)
        value
      else
        raise TypeError, "Expected #{expected_type.inspect} but got #{value.inspect}"
      end
    end
  
    def expected_type
      @options[:type] || String
    end
    
    def type_cast(value)
      if value.is_a?(expected_type)
        value
      elsif (converter = CONVERTERS[expected_type]) && (value =~ FORMATS[expected_type])
        converter.call(value)
      else
        value
      end
    end
    
    def append_validations!
      if f = FORMATS[expected_type]
        @owner_class.validates_format_of @name, :with=>f, :unless => lambda {|obj| obj.send(name).is_a? expected_type }
      end
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
        write_inheritable_hash(:model_attributes, {name.to_s=>Attribute.new(name, self, options)})
      end

      def define_attribute_methods(force = false)
        return unless model_attributes
        undefine_attribute_methods if force
        super(model_attributes.keys)
      end
    end
  
    included do
      class_inheritable_hash :model_attributes

      attribute_method_suffix("", "=")
    end
  
    module InstanceMethods
      def write_attribute(name, value)
        if ma = self.class.model_attributes[name.to_s]
          value = ma.check_value!(value)
        end
        @attributes[name] = value
      end

      def read_attribute(name)
        if ma = self.class.model_attributes[name.to_s]
          ma.type_cast(@attributes[name])
        else
          @attributes[name]
        end
      end

      def attributes=(attributes)
        attributes.each do |(name, value)|
          send("#{name}=", value)
        end
      end

      protected
        def attribute_method?(name)
          @attributes.include?(name.to_s) || model_attributes[name.to_s]
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

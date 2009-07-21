module CassandraObject
  class Attribute
    FORMATS = {}
    FORMATS[Date] = /^\d{4}-\d{2}-\d{2}$/
    FORMATS[Integer] = /^-?\d+$/
    FORMATS[Float]   = /^-?\d*\.\d*$/
    
    CONVERTERS = {}
    CONVERTERS[Date] = Proc.new do |str|
      Date.strptime("%Y-%m-%d")
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
      @owner_class.class_eval <<-eos
        def #{@name}
          val = read_attribute(:#{@name})
          if val.is_a?(#{expected_type.inspect})
            val
          else
            self.class.attributes[:#{@name}].type_cast(val)
          end
        end
        
        def #{@name}=(val)
          write_attribute(:#{@name}, val)
        end
            
      eos
    end
        
  end

  module Attributes
    extend ActiveSupport::Concern
    module ClassMethods
      def attribute(name, options)
        (self.model_attributes ||= ActiveSupport::OrderedHash.new)[name.to_s] = Attribute.new(name, self, options)
      end
    end
  
    included do
      class_inheritable_accessor :model_attributes
    end
  
    module InstanceMethods
      # All this stuff should probably come from AMo
      def method_missing(name, *args)
        name = name.to_s
        if name =~ /^(.*)=$/
          write_attribute($1, args.first)
        elsif @attributes.include?(name) || model_attributes[name]
          read_attribute(name)
        else
          super(name, *args)
        end
      end

      def write_attribute(name, value)
        value = self.class.model_attributes[name].check_value!(value)
        @changed_attribute_names << name
        @attributes[name] = value
      end

      def read_attribute(name)
        self.class.model_attributes[name].type_cast(@attributes[name])
      end

      def changed_attributes
        @changed_attribute_names.inject({}) do |memo, name|
          memo[name] = send(name)
          memo
        end
      end

      def attributes=(attributes)
        attributes.each do |(name, value)|
          send("#{name}=", value)
        end
      end

      def attributes_changed!(attributes)
        attributes.each do |attr_name|
          @changed_attribute_names << attr_name.to_s
        end
      end
    end
  end
end
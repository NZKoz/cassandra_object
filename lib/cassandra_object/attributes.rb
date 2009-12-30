ActiveSupport::JSON::Encoding.use_standard_json_time_format = true

module CassandraObject
  module AttributeHandlers
    
    class BaseAttributeHandler
      def format
        self.class.const_get("FORMAT")
      end
      
      def expected_type
        self.class.const_get("TYPE")
      end
      
      def serialize(object)
        object && ActiveSupport::JSON.encode(object)
      end
      
      def parse(string)
        string && ActiveSupport::JSON.decode(string)
      end
      
      def can_parse?(string)
        if !format || !string
          true
        else
          string =~ format
        end
      end
    end
    
    class StringHandler < BaseAttributeHandler
      FORMAT = nil
      TYPE   = String
      def parse(s)
        s
      end
      
      def serialize(s)
        s
      end
    end
    
    class DateHandler < BaseAttributeHandler
      FORMAT = /^\d{4}\-\d{2}\-\d{2}$/
      TYPE   = Date
      STRING_FORMAT = "%Y-%m-%d"
      
      def parse(string)
        string && Date.strptime(string, STRING_FORMAT)
      end
      
      def serialize(date)
        date && date.strftime(STRING_FORMAT)
      end
    end
    
    class IntegerHandler < BaseAttributeHandler
      FORMAT = /^-?\d+$/
      TYPE   = Integer
      
      def parse(string)
        string && Integer(string)
      end
      
      def serialize(int)
        int && int.to_s
      end
    end
    
    class FloatHandler < BaseAttributeHandler
      FORMAT = /^-?\d*\.\d*$/
      TYPE   = Float
      
      def parse(string)
        string && Float(string)
      end
      
      def serialize(string)
        string && string.to_s
      end
    end
    
    class TimeHandler < BaseAttributeHandler
      FORMAT = /\A\s*
                -?\d+-\d\d-\d\d
                T
                \d\d:\d\d:\d\d
                (\.\d*)?
                (Z|[+-]\d\d:\d\d)?
                \s*\z/ix # lifted from the implementation of Time.xmlschema
      TYPE   = Time
      
      def parse(string)
        string && Time.xmlschema(string)
      end
      
      def serialize(time)
        time && time.xmlschema
      end
    end
    
    class TimeWithZoneHandler < TimeHandler
      def parse(string)
        string && super(string).in_time_zone
      end
      
      def serialize(time)
        time && super(time.utc)
      end
    end
    
    class ObjectHandler < BaseAttributeHandler
      FORMAT = nil
      TYPE = Object
    end
    
    class UUIDHandler < BaseAttributeHandler
      FORMAT = /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/i
      TYPE = Cassandra::UUID
      
      def parse(str)
        Cassandra::UUID.new(str)
      end
      
      def serialize(uuid)
        super(uuid.to_guid)
      end
        
    end
    
  end
  class Attribute
    HANDLERS = {
      :string         => AttributeHandlers::StringHandler,
      :date           => AttributeHandlers::DateHandler,
      :integer        => AttributeHandlers::IntegerHandler,
      :float          => AttributeHandlers::FloatHandler,
      :time           => AttributeHandlers::TimeHandler,
      :time_with_zone => AttributeHandlers::TimeWithZoneHandler,
      :hash           => AttributeHandlers::ObjectHandler,
      :uuid           => AttributeHandlers::UUIDHandler
    }
    attr_reader :name, :options
    def initialize(name, owner_class, options)
      @name = name.to_s
      @owner_class = owner_class
      @options = options
      
      assign_attribute_handler
      
      append_validations!
    end
    
    def assign_attribute_handler
      if @options[:type].is_a?(Symbol) && (clazz = HANDLERS[@options[:type]])
        @attribute_handler = clazz.new
      else
        @attribute_handler = @options[:type]
      end
    end
    
    def serialize(value)
      @attribute_handler.serialize(value)
    end

    def parse(value)
      @attribute_handler.parse(value)
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
      @attribute_handler.expected_type
    end

    def type_cast(value)
      if value.nil?
        nil
      elsif value.is_a?(expected_type)
        value
      elsif @attribute_handler.can_parse?(value)
        @attribute_handler.parse(value)
      end
    end

    def append_validations!
      if f = @attribute_handler.format
        @owner_class.validates_format_of @name, :with => f, :unless => lambda {|obj| obj.send(name).is_a? expected_type }, :allow_nil => @options[:allow_nil]
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
        Attribute.new(name, self, options).tap do |attr|
          write_inheritable_hash(:model_attributes, {name => attr}.with_indifferent_access)
          attr.define_methods!
        end
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
        if ma = self.class.model_attributes[name.to_sym]
          value = ma.check_value!(value)
        end
        @attributes[name] = value
      end

      def read_attribute(name)
        if ma = self.class.model_attributes[name]
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
          @attributes.include?(name.to_sym) || model_attributes[name.to_sym]
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

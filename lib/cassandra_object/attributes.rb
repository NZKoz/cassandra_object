module CassandraObject
  class Attribute
    attr_reader :name
    def initialize(name, options)
      @name = name.to_s
      @options = options
    end
  
  
    # I think this should live somewhere 
    def check_value!(value)
      value
    end
  
    def expected_type
      @options[:type] || String
    end
  end

  module Attributes
    extend ActiveSupport::Concern
    module ClassMethods
      def attribute(name, options)
        (self.model_attributes ||= ActiveSupport::OrderedHash.new)[name.to_s] = Attribute.new(name, options)
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
        @attributes[name]
      end

      def changed_attributes
        if new_record?
          @attributes
        else
          @changed_attribute_names.inject({}) do |memo, name|
            memo[name] = read_attribute(name)
            memo
          end
        end
      end

      def attributes=(attributes)
        attributes.each do |(name, value)|
          send("#{name}=", value)
        end
      end
    end
  end
end
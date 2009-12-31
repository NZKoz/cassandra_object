module CassandraObject
  class Attribute

    attr_reader :name
    def initialize(name, owner_class, options)
      @name = name.to_s
      @owner_class = owner_class
      @options = options

      define_methods!
    end

    def converter
      "CassandraObject::#{expected_type.to_s.gsub(/.*::/, '')}Type".constantize
    end

    def check_value!(value)
      converter.encode(value) unless value.nil? && @options[:allow_nil]
      value
    end

    def expected_type
      @options[:type] || String
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
        write_inheritable_hash(:model_attributes, {name => Attribute.new(name, self, options)})
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
          @attributes[name] = ma.check_value!(value)
        end
      end

      def read_attribute(name)
        @attributes[name]
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

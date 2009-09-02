require 'active_support/core_ext/object/tap'

module CassandraObject
  module Dirty
    extend ActiveSupport::Concern
    include ActiveModel::Dirty

    module InstanceMethods
      def attributes_changed!(attributes)
        attributes.each do |attr_name|
          attribute_will_change!(attr_name)
        end
      end

      def save
        super.tap { changed_attributes.clear }
      end

      def write_attribute(name, value)
        name = name.to_s
        unless attribute_changed?(name)
          old = read_attribute(name)
          changed_attributes[name] = old if old != value
        end
        super
      end
    end
  end
end

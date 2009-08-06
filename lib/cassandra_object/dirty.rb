module CassandraObject
  module Dirty
    extend ActiveSupport::Concern

    included do
      attr_reader :changed_attribute_names

      attribute_method_suffix("_changed?")
    end

    module InstanceMethods
      def changed?
        !changed_attribute_names.empty?
      end

      def changed
        changed_attribute_names
      end

      def save
        super.tap { changed_attribute_names.clear }
      end

      def attributes_changed!(attributes)
        attributes.each do |attr_name|
          changed_attribute_names << attr_name
        end
      end

      def changed_attributes
        changed_attribute_names.inject(Hash.new) do |memo, name|
          memo[name.to_s] = read_attribute(name)
          memo
        end
      end

      def write_attribute(name, value)
        @changed_attribute_names << name
        super
      end

      private
        # Handle <tt>*_changed?</tt> for +method_missing+.
        def attribute_changed?(attr)
          changed_attributes.include?(attr)
        end
    end
  end
end


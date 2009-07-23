module CassandraObject
  module Dirty
    extend ActiveSupport::Concern

    def changed?
      !changed_attributes.empty?
    end

    def changed
      changed_attributes.keys
    end

    def save
      super.tap { changed_attributes.clear }
    end

    def attributes_changed!(attributes)
      attributes.each do |attr_name|
        changed_attributes[name] = send(attr_name)
      end
    end

    private
      def changed_attributes
        @changed_attributes ||= {}
      end

      def write_attribute(name, value)
        if changed_attributes.include?(name)
          old = changed_attributes[name]
          changed_attributes.delete(name) unless attribute_changed?(name, old, value)
        else
          old = read_attribute(name)
          changed_attributes[name] = old if attribute_changed?(name, old, value)
        end

        super
      end

      def attribute_changed?(name, old, value)
        old != self.class.model_attributes[name].type_cast(value)
      end
  end
end

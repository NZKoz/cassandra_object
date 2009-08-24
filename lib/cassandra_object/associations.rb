require 'cassandra_object/associations/one_to_many'
require 'cassandra_object/associations/one_to_one'

module CassandraObject
  module Associations
    extend ActiveSupport::Concern
    
    included do
      class_inheritable_hash :associations
    end

    module ClassMethods
      def association(association_name, options= {})
        if options[:unique]
          write_inheritable_hash(:associations, {association_name => OneToOneAssociation.new(association_name, self, options)})
        else
          write_inheritable_hash(:associations, {association_name => OneToManyAssociation.new(association_name, self, options)})
        end
      end
      
      def remove(key)
        connection.remove("#{name}Relationships", key.to_s)
        super
      end
    end
  end
end
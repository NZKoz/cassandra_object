require 'cassandra_object/associations/one_to_many'
require 'cassandra_object/associations/one_to_one'

module CassandraObject
  module Associations
    extend ActiveSupport::Concern
    
    included do
      class_inheritable_accessor :associations
      self.associations = ActiveSupport::OrderedHash.new
    end

    module ClassMethods
      def association(association_name, options= {})
        if options[:unique]
          associations[association_name] = OneToOneAssociation.new(association_name, self, options)
        else
          associations[association_name] = OneToManyAssociation.new(association_name, self, options)
        end
      end
      
      def remove(key)
        connection.remove("#{name}Relationships", key)
        super
      end
    end
  end
end
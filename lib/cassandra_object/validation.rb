module CassandraObject
  module Validation
    extend ActiveSupport::Concern
    depends_on ActiveModel::Validations
    
    included do
      define_callbacks :before_validation
    end
    
    module InstanceMethods
      def save
        run_callbacks :before_validation
        if valid?
          super
        else
          self
        end
      end
    end
  end
end
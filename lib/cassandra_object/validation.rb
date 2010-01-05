module CassandraObject
  module Validation
    class RecordInvalidError < StandardError
      attr_reader :record
      def initialize(record)
        @record = record
        super("Invalid record: #{@record.errors.full_messages.to_sentence}")
      end
      
      def self.raise_error(record)
        raise new(record)
      end
    end
    extend ActiveSupport::Concern
    include ActiveModel::Validations
    
    included do
      define_model_callbacks :validation
      if CassandraObject.old_active_support
        define_callbacks :validate
      else
        define_callbacks :validate, :scope => :name
      end
    end
    
    module ClassMethods
      def create!(attributes)
        returning new(attributes), &:save!
      end
    end
    
    module InstanceMethods
      def valid?
        run_callbacks :validation do
          super
        end
      end

      def save
        if valid?
          super
        else
          false
        end
      end
      
      def save!
        save || RecordInvalidError.raise_error(self)
      end
      
      if CassandraObject.old_active_support
        def _run_validate_callbacks
          run_callbacks :validate
        end
      end
    end
  end
end
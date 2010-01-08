module CassandraObject
  module Callbacks
    extend ActiveSupport::Concern
    include ActiveSupport::Callbacks
    
    included do
      define_model_callbacks :save, :create, :destroy, :update
    end
    
    module ClassMethods
      def define_model_callbacks(*callbacks)
        callbacks.each do |callback|
          define_callbacks "before_#{callback}"
          define_callbacks "after_#{callback}"
        end
      end
    end
    
    module InstanceMethods
      def run_callbacks(callback)
        if block_given?
          unless false == super("before_#{callback}")
            yield.tap do
              super("after_#{callback}")
            end
          end
        else
          super
        end
      end
    end
  end
end
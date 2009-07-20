module CassandraObject
  module Persistence
    extend ActiveSupport::Concern
    
    module ClassMethods
      def get(key)
        # Can't use constructor for both 'fetch' and 'new'
        # take approach from AR.
        new(key, connection.get(column_family, key))
      end

      def all(keyrange = ''..'', options = {})
        connection.get_key_range(column_family, keyrange, options[:limit] || 100).map {|key| get(key) }
      end
      
      def first(keyrange = ''..'', options = {})
        all(keyrange, options.merge(:limit=>1)).first
      end
      
      def create(attributes)
        new(nil, attributes).save
      end

      def write(key, attributes)
        unless key
          key = next_key
        end
        connection.insert(column_family, key, attributes.stringify_keys)
        return key
      end
    end
    
    module InstanceMethods
      def save
        if was_new_record = new_record?
          run_callbacks :before_create
        end
        run_callbacks :before_save
        @key ||= self.class.write(key, changed_attributes)
        run_callbacks :after_save
        run_callbacks :after_create if was_new_record
        self
      end

      def new_record?
        @key.nil?
      end
    end
  end
end
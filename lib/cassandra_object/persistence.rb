module CassandraObject
  module Persistence
    extend ActiveSupport::Concern
    
    module ClassMethods
      def get(id)
        # Can't use constructor for both 'fetch' and 'new'
        # take approach from AR.
        new(id, connection.get(column_family, id))
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

      def write(id, attributes)
        unless id
          id = next_id
        end
        connection.insert(column_family, id, attributes.stringify_keys)
        return id
      end
    end
    
    module InstanceMethods
      def save
        if was_new_record = new_record?
          run_callbacks :before_create
        end
        run_callbacks :before_save
        @id ||= self.class.write(id, changed_attributes)
        run_callbacks :after_save
        run_callbacks :after_create if was_new_record
        self
      end
    end
  end
end
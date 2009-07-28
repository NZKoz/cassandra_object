module CassandraObject
  module Persistence
    extend ActiveSupport::Concern
    
    module ClassMethods
      def get(key, options = {})
        multi_get([key], options).values.first
      end

      DEFAULT_MULTI_GET_OPTIONS = {
        :quorum=>false,
        :limit=>100
      }

      def multi_get(keys, options = {})
        options = DEFAULT_MULTI_GET_OPTIONS.merge(options)

        if options[:quorum]
          consistency = CassandraClient::Consistency::QUORUM
        else
          consistency = CassandraClient::Consistency::WEAK
        end

        attribute_results = connection.multi_get(column_family, keys, nil, nil, options[:limit], consistency)

        attribute_results.inject(ActiveSupport::OrderedHash.new) do |memo, (key, attributes)|
          memo[key] = if attributes.empty?
            nil
          else
            instantiate(key, attributes)
          end
          memo
        end
      end
      
      def remove(key)
        connection.remove(column_family, key)
      end

      def all(keyrange = ''..'', options = {})
        connection.get_key_range(column_family, keyrange, options[:limit] || 100).map {|key| get(key) }
      end
      
      def first(keyrange = ''..'', options = {})
        all(keyrange, options.merge(:limit=>1)).first
      end
      
      def create(attributes)
        returning new(attributes) do |object|
          object.save
        end
      end

      def write(key, attributes)
        returning(key || next_key) do |key|
          connection.insert(column_family, key, attributes.stringify_keys)
        end
      end

      def instantiate(key, attributes)
        returning allocate do |object|
          object.instance_variable_set("@key", key)
          object.instance_variable_set("@attributes", attributes.with_indifferent_access)
          object.instance_variable_set("@changed_attribute_names", Set.new)
        end
      end
    end
    
    module InstanceMethods
      def save
        if was_new_record = new_record?
          run_callbacks :before_create
        end
        run_callbacks :before_save
        
        returned_key = self.class.write(key, changed_attributes)
        @key ||= returned_key
        run_callbacks :after_save
        run_callbacks :after_create if was_new_record
        @new_record = false
        true
      end

      def new_record?
        @new_record || false
      end
      
      def destroy
        run_callbacks :before_destroy
        self.class.remove(key)
        run_callbacks :after_destroy
      end
    end
  end
end
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
        limit = options[:limit] || 100
        if options[:quorum]
          consistency = Cassandra::Consistency::QUORUM
        else
          consistency = Cassandra::Consistency::ONE
        end
        
        attribute_results = connection.multi_get(column_family, keys.map(&:to_s), :count=>limit, :consistency=>consistency)
        
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
        connection.remove(column_family, key.to_s)
      end

      def all(keyrange = ''..'', options = {})
        connection.get_key_range(column_family, keyrange, :count=>(options[:limit] || 100)).map {|key| get(key) }
      end
      
      def first(keyrange = ''..'', options = {})
        all(keyrange, options.merge(:limit=>1)).first
      end
      
      def create(attributes)
        returning new(attributes) do |object|
          object.save
        end
      end

      def write(key, attributes, schema_version)
        returning(key || next_key(attributes)) do |key|
          connection.insert(column_family, key.to_s, encode_columns_hash(attributes, schema_version))
        end
      end

      def instantiate(key, attributes)
        returning allocate do |object|
          object.instance_variable_set("@schema_version", attributes.delete('schema_version'))
          object.instance_variable_set("@key", parse_key(key))
          object.instance_variable_set("@attributes", decode_columns_hash(attributes).with_indifferent_access)
        end
      end
      
      def encode_columns_hash(attributes, schema_version)
        (attributes.merge({:schema_version => schema_version})).inject(Hash.new) do |memo, (column_name, value)|
          memo[column_name.to_s] = ActiveSupport::JSON.encode(value)
          memo
        end
      end
      
      def decode_columns_hash(attributes)
        attributes.inject(Hash.new) do |memo, (column_name, value)|
          memo[column_name.to_s] = ActiveSupport::JSON.decode(value)
          memo
        end
      end
    end
    
    module InstanceMethods
      def save
        if was_new_record = new_record?
          run_callbacks :before_create
        end
        run_callbacks :before_save

        changed_attributes = changed.inject({}) { |h, n| h[n] = read_attribute(n); h }
        returned_key = self.class.write(key, changed_attributes, schema_version)
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

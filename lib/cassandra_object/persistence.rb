module CassandraObject
  module Persistence
    extend ActiveSupport::Concern
    included do
      class_inheritable_accessor :write_consistency
      class_inheritable_accessor :read_consistency
    end

    VALID_READ_CONSISTENCY_LEVELS = [:one, :quorum, :all]
    VALID_WRITE_CONSISTENCY_LEVELS = VALID_READ_CONSISTENCY_LEVELS + [:zero]

    module ClassMethods
      def consistency_levels(levels)
        if levels.has_key?(:write)
          unless valid_write_consistency_level?(levels[:write])
            raise ArgumentError, "Invalid write consistency level. Valid levels are: #{VALID_WRITE_CONSISTENCY_LEVELS.inspect}. You gave me #{levels[:write].inspect}"
          end
          self.write_consistency = levels[:write]
        end

        if levels.has_key?(:read)
          unless valid_read_consistency_level?(levels[:read])
            raise ArgumentError, "Invalid read consistency level. Valid levels are #{VALID_READ_CONSISTENCY_LEVELS.inspect}. You gave me #{levels[:write].inspect}"
          end
          self.read_consistency = levels[:read]
        end
      end

      def get(key, options = {})
        multi_get([key], options).values.first
      end

      def multi_get(keys, options = {})
        options = {:consistency => self.read_consistency || :quorum, :limit => 100}.merge(options)
        options[:consistency] = case options[:consistency]
        when :quorum
          Cassandra::Consistency::QUORUM
        when :one
          Cassandra::Consistency::ONE
        else
          raise ArgumentError, "Invalid read consistency level: '#{options[:consistency]}'. Valid options are [:quorum, :one]"
        end

        attribute_results = connection.multi_get(column_family, keys.map(&:to_s), :count=>options[:limit], :consistency=>options[:consistency])

        attribute_results.inject(ActiveSupport::OrderedHash.new) do |memo, (key, attributes)|
          if attributes.empty?
            memo[key] = nil
          else
            memo[parse_key(key)] = instantiate(key, attributes)
          end
          memo
        end
      end

      def remove(key)
        connection.remove(column_family, key.to_s, :consistency => (write_consistency || Cassandra::Consistency::QUORUM))
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
        returning(key) do |key|
          connection.insert(column_family, key.to_s, encode_columns_hash(attributes, schema_version), :consistency => (write_consistency||Cassandra::Consistency::QUORUM))
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
        attributes.inject(Hash.new) do |memo, (column_name, value)|
          memo[column_name.to_s] = model_attributes[column_name.to_sym].converter.encode(value)
          memo
        end.merge({"schema_version" => schema_version.to_s})
      end

      def decode_columns_hash(attributes)
        attributes.inject(Hash.new) do |memo, (column_name, value)|
          memo[column_name.to_s] = model_attributes[column_name.to_sym].converter.decode(value)
          memo
        end
      end

      protected
      def valid_read_consistency_level?(level)
        !!VALID_READ_CONSISTENCY_LEVELS.include?(level)
      end

      def valid_write_consistency_level?(level)
        !!VALID_WRITE_CONSISTENCY_LEVELS.include?(level)
      end
    end

    module InstanceMethods
      def save
        if was_new_record = new_record?
          run_callbacks :before_create
        end
        run_callbacks :before_save

        changed_attributes = changed.inject({}) { |h, n| h[n] = read_attribute(n); h }
        @key ||= self.class.next_key(self)
        self.class.write(key, changed_attributes, schema_version)
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
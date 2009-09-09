require 'cassandra_object/identity/abstract_key_factory'
require 'cassandra_object/identity/key'
require 'cassandra_object/identity/uuid_key_factory'
require 'cassandra_object/identity/natural_key_factory'

module CassandraObject
  # Some docs will be needed here but the gist of this is simple.  Instead of returning a string, Base#key  now returns a key object.
  # There are corresponding key factories which generate them
  module Identity
    extend ActiveSupport::Concern
    module ClassMethods
      # Indicate what kind of key the model will have: uuid or natural
      #
      # @param [:uuid, :natural] the type of key
      # @param the options you want to pass along to the key factory (like :attributes => :name, for a natural key).
      # 
      def key(name_or_factory = :uuid, *options)
        @key_factory = case name_or_factory
        when :uuid
          UUIDKeyFactory.new
        when :natural
          NaturalKeyFactory.new(*options)
        else
          name_or_factory
        end
      end
    
      def next_key(object = nil)
        returning(@key_factory.next_key(object)) do |key|
          raise "Keys may not be nil" if key.nil?
        end
      end
      
      def parse_key(string)
        @key_factory.parse(string)
      end
    end
    
    module InstanceMethods

      def ==(comparison_object)
        comparison_object.equal?(self) ||
          (comparison_object.instance_of?(self.class) &&
            comparison_object.key == key &&
            !comparison_object.new_record?)
      end

      def eql?(comparison_object)
        self == (comparison_object)
      end

      def hash
        key.to_s.hash
      end
      
      def to_param
        key.to_param
      end
    end
  end
end

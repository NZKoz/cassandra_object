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
      def key(name = :uuid, &blk)
        @key_factory = case name
        when :uuid
          UUIDKeyFactory.new
        end
      end
    
      def next_key(object = nil)
        @key_factory.next_key(object)
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

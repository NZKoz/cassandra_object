module CassandraObject
  
  # Some docs will be needed here but the gist of this is simple.  Instead of returning a string, Base#key  now returns a key object.
  # There are corresponding key factories which generate them
  module Identity
    
    class UUID < Cassandra::UUID
      # to_param should return a nice-readable representation of the key suitable to chuck into URLs
      def to_param
        to_guid
      end
      
      # to_s should return the bytes which will be written to cassandra both as keys and values for associations.
      def to_s
        # FIXME - this should probably write the raw bytes 
        # but it's very hard to debug without this for now.
        to_guid
      end
    end
    
    
    # Key factories need to support 3 operations
    class UUIDKeyFactory
      # Next key takes an object and returns the key object it should use.
      # object will be ignored with synthetic keys but could be useful with natural ones
      def next_key(object)
        UUID.new
      end
      
      # Parse should create a new key object from the 'to_param' format
      def parse(string)
        UUID.new(string)
      end
      
      # create should create a new key object from the cassandra format.
      def create(string)
        UUID.new(string)
      end
    end
    
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

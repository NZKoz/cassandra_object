module CassandraObject
  module Identity
    # Key factories need to support 3 operations
    class UUIDKeyFactory < AbstractKeyFactory
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
  end
end


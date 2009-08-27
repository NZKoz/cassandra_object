module CassandraObject
  module Identity
    # An "interface" that keys need to implement
    # 
    # You don't have to include this. But, there's no reason I can think of not to.
    #
    module Key
      # to_param should return a nice-readable representation of the key suitable to chuck into URLs
      #
      # @return [String] a nice readable representation of the key suitable for URLs
      def to_param; end
        
      # to_s should return the bytes which will be written to cassandra both as keys and values for associations.
      #
      # @return [String] the bytes which will be written to cassandra as keys
      def to_s; end
    end
  end
end


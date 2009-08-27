module CassandraObject
  module Identity
    # Key factories need to support 3 operations
    class AbstractKeyFactory
      # Next key takes an object and returns the key object it should use.
      # object will be ignored with synthetic keys but could be useful with natural ones
      #
      # @param [CassandraObject::Base] the object that needs a new key
      # @return [#to_s#to_param] the key
      #
      def next_key(object)
        raise NotImplementedError, "#{self.class.name}#next_key isn't implemented."
      end

      # Parse should create a new key object from the 'to_param' format
      #
      # @param [String] the result of calling key.to_param
      # @return [#to_s#to_param] the parsed key
      #
      def parse(string)
        raise NotImplementedError, "#{self.class.name}#parse isn't implemented."
      end


      # create should create a new key object from the cassandra format.
      #
      # @param [String] the result of calling key.to_s
      # @return [#to_param#to_s] the key
      #
      def create(string)
        UUID.new(string)
      end
    end
  end
end


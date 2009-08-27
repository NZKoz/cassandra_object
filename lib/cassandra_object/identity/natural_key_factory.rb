module CassandraObject
  module Identity
    class NaturalKeyFactory < AbstractKeyFactory
      class NaturalKey
        include Key

        attr_reader :value

        def initialize(value)
          @value = value
        end

        def to_s
          value
        end

        def to_param
          value
        end
      end

      attr_reader :attributes, :separator

      def initialize(options)
        @attributes = [*options[:attributes]]
        @separator  = "-"
      end

      def next_key(object)
        NaturalKey.new(attributes.map { |a| object.send(a) }.join(separator))
      end

      def parse(paramized_key)
        NaturalKey.new(paramized_key)
      end

      def create(paramized_key)
        NaturalKey.new(paramized_key)
      end
    end
  end
end


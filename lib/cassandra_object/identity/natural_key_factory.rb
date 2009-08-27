module CassandraObject
  module Identity
    class NaturalKeyFactory < AbstractKeyFactory
      class NaturalKey
        include Key

        attr_reader :fragments

        def initialize(fragments)
          @fragments = fragments
        end

        def to_s
          fragments.join
        end

        def to_param
          fragments.join
        end
      end

      attr_reader :attributes

      def initialize(options)
        @attributes = [*options[:attributes]]
      end

      def next_key(object)
        NaturalKey.new(attributes.map { |a| object.send(a) })
      end

      def parse(paramized_key)
        NaturalKey.new(paramized_key.split)
      end

      def create(paramized_key)
        NaturalKey.new(paramized_key.split)
      end
    end
  end
end


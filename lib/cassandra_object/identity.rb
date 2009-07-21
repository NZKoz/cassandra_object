module CassandraObject
  module Identity
    extend ActiveSupport::Concern
    module ClassMethods
      def key(name = :uuid, &blk)
        if block_given?
          @key = blk
        else
          @key = case name
          when :uuid
            lambda { [Time.now.utc.strftime("%Y%m%d%H%M%S"), Process.pid, rand(1024)] * "" }
          end
        end
      end
    
      def next_key
        @key.call
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
        key.hash
      end
    end
  end
end
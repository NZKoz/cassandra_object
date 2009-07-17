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
    
      def next_id
        @key.call
      end
    end
  end
end
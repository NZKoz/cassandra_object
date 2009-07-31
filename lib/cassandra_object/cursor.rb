module CassandraObject
  class Cursor
    def initialize(target_class, column_family, key, super_column, options={})
      @target_class  = target_class
      @column_family = column_family
      @key           = key
      @super_column  = super_column
      @options       = options
    end
    
    def find(number_to_find)
      limit       = number_to_find
      objects     = CassandraObject::Collection.new
      out_of_keys = false

      if start_with = @options[:start_after]
        limit += 1
      end
      
      while objects.size < number_to_find && !out_of_keys
        # start_with not supported in cassandra_client yet
        index_results = connection.get(@column_family, @key.to_s, @super_column, nil, limit)
        keys = index_results.keys
        values = index_results.values
        
        
        missing_keys = []
        out_of_keys  = keys.size < limit

        if start_with
          keys.delete(start_with)
          # Start where we left off if we need to.
          start_with = keys.last
        end

        results = @target_class.multi_get(values)
        
        results.each do |(key, result)|
          if result.nil?
            missing_keys << key
          end
        end
        
        unless missing_keys.empty?
          @target_class.multi_get(missing_keys, :quorum=>true).each do |(key, result)|
            if result.nil?
              index_key = index_results.index(key)
              connection.remove(@column_family, @key, @super_column, index_key)
              results.delete(key)
            else
              results[key] = result
            end
          end
        end
        
        results.values.each do |o|
          objects << o
        end
        
        objects.last_column_name = keys.last
        limit = number_to_find - results.size
        
      end
      
      return objects
    end
    
    def connection
      @target_class.connection
    end
  end
end
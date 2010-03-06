module CassandraObject
  class Cursor
    def initialize(target_class, column_family, key, super_column, options={})
      @target_class  = target_class
      @column_family = column_family
      @key           = key.to_s
      @super_column  = super_column
      @options       = options
      @validators    = []
    end
    
    def find(number_to_find)
      limit       = number_to_find
      objects     = CassandraObject::Collection.new
      out_of_keys = false

      if start_with = @options[:start_after]
        limit += 1
      else
        start_with = nil
      end
      
      while objects.size < number_to_find && !out_of_keys
        index_results = connection.get(@column_family, @key, @super_column, :count=>limit,
                                                                            :start=>start_with,
                                                                            :reversed=>@options[:reversed])

        out_of_keys  = index_results.size < limit

        if !start_with.blank?
          index_results.delete(start_with)
        end

        keys = index_results.keys
        values = index_results.values
        
        missing_keys = []
        
        results = values.empty? ? {} : @target_class.multi_get(values)
        results.each do |(key, result)|
          if result.nil?
            missing_keys << key
          end
        end
    
        unless missing_keys.empty?
          @target_class.multi_get(missing_keys, :quorum=>true).each do |(key, result)|
            index_key = index_results.index(key)
            if result.nil?
              remove(index_key)
              results.delete(key)
            else
              results[key] = result
            end
          end
        end

        results.values.each do |o|
          if @validators.all? {|v| v.call(o) }
            objects << o
          else
            remove(index_results.index(o.key))
          end
        end
        
        start_with = objects.last_column_name = keys.last
        limit = (number_to_find - results.size) + 1
        
      end
      
      return objects
    end
    
    def connection
      @target_class.connection
    end
    
    def remove(index_key)
      connection.remove(@column_family, @key, @super_column, index_key)
    end
    
    def validator(&validator)
      @validators << validator
    end
  end
end
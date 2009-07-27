module CassandraObject
  class OneToManyAssociation
    def initialize(association_name, owner_class, options)
      @association_name  = association_name.to_s
      @owner_class       = owner_class
      @target_class_name = options[:class_name] || association_name.to_s.singularize.camelize
      @options           = options
      
      define_methods!
    end
    
    def find(owner, options = {})
      start        = options[:start_after]
      limit        = options[:limit] || 100
      missing_keys = []

      if start
        limit += 1
      end

      # FIXME - start not supported in cassandra_client yet
      keys = connection.get(column_family, owner.key, @association_name, nil, limit).keys

      if start
        keys.delete(start)
      end

      out_of_keys  = keys.size < limit

      results = target_class.multi_get(keys)

      results.each do |(key, result)|
        if result.nil?
          missing_keys << key
        end
      end

      unless missing_keys.empty?
        target_class.multi_get(missing_keys, :quorum=>true).each do |(key, result)|
          if result.nil?
            connection.remove(column_family, owner.key, @association_name, key)
            results.delete(key)
          else
            results[key] = result
          end
        end
      end

      # We've trimmed out the read-repair stuff, now check if we've grabbed enough or the max
      if results.size == limit || out_of_keys
        results.values
      else
        # We have to fetch more, pass start and limit on down and recurse
        # FIXME this isn't erlang, this should probably iterate instead
        number_remaining_to_fetch = limit - results.size
        recursive_options = options.merge(:limit=>number_remaining_to_fetch,
                                          :start_after=>keys.last)
        results.values + find(owner, recursive_options)
      end
    end
    
    def add(owner, record, set_inverse = true)
      connection.insert(column_family, owner.key, {@association_name=>{record.key=>nil}})
      if has_inverse? && set_inverse
        inverse.set_inverse(record, owner)
      end
    end
    
    def column_family
      @owner_class.to_s + "Relationships"
    end
    
    def connection
      @owner_class.connection
    end
    
    def target_class
      @target_class ||= @target_class_name.constantize
    end
    
    def new_proxy(owner)
      OneToManyAssociationProxy.new(self, owner)
    end
    
    def has_inverse?
      @options[:inverse_of]
    end
    
    def inverse
      has_inverse? && target_class.associations[@options[:inverse_of]]
    end
    
    def set_inverse(owner, record)
      add(owner, record, false)
    end
    
    def define_methods!
      @owner_class.class_eval <<-eos
        def #{@association_name}
          @_#{@association_name} ||= self.class.associations[:#{@association_name}].new_proxy(self)
        end
      eos
    end
  end
  
  class OneToManyAssociationProxy
    def initialize(association, owner)
      @association = association
      @owner       = owner
    end
    
    include Enumerable
    def each
      target.each do |i|
        yield i
      end
    end
    
    def <<(record)
      @association.add(@owner, record)
      if loaded?
        @target << record
      end
    end
    
    def all(options = {})
      @association.find(@owner, options)
    end

    def target
      @target ||= begin
        @loaded = true
        @association.find(@owner)
      end
    end
    
    alias to_a target
    
    def loaded?
      defined?(@loaded) && @loaded
    end
  end
end
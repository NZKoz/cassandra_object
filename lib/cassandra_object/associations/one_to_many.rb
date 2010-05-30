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
      reversed = options.has_key?(:reversed) ? options[:reversed] : @options[:reversed]
      cursor   = CassandraObject::Cursor.new(target_class, column_family, owner.key.to_s, @association_name, :start_after => options[:start_after], :reversed => reversed)
      cursor.find(options[:limit] || 100)
    end
    
    def add(owner, record, set_inverse = true)
      connection.insert(column_family, owner.key.to_s, {@association_name=>{new_key=>record.key.to_s}})
      if has_inverse? && set_inverse
        inverse.set_inverse(record, owner)
      end
    end
    
    def new_key
      SimpleUUID::UUID.new
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
    
    # Get the targets of this association proxy
    #
    # @param  [Hash] options the options with which to modify this query
    # @option options [String]  :start_after the key after which to start returning results
    # @option options [Boolean] :reversed (false or association default) return the results in reverse order
    # @option options [Integer] :limit the max number of results to return
    # @return [Array<CassandraObject::Base>] an array of objects of type self#target_class
    #
    def all(options = {})
      @association.find(@owner, options)
    end
    
    # Create a record of the associated type with 
    # the supplied attributes and add it to this 
    # association
    #
    # @param  [Hash] attributes the attributes with which to create the object
    # @return [CassandraObject::Base] the newly created object
    #
    def create(attributes)
      returning @association.target_class.create(attributes) do |record|
        if record.valid?
          self << record
        end
      end
    end
    
    def create!(attributes)
      returning @association.target_class.create!(attributes) do |record|
        self << record
      end
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

module CassandraObject
  module Associations
    extend ActiveSupport::Concern
    
    included do
      class_inheritable_accessor :associations
      self.associations = ActiveSupport::OrderedHash.new
    end
    
    class OneToManyAssociation
      def initialize(association_name, owner_class, options)
        @association_name  = association_name.to_s
        @owner_class       = owner_class
        @target_class_name = options[:class_name] || association_name.to_s.singularize.camelize
        @options           = options
        
        define_methods!
      end
      
      def find(owner)
        res = connection.get(column_family, owner.key, @association_name)
        res.keys.map {|key| target_class.get(key) }
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
    
    class OneToOneAssociation
      def initialize(association_name, owner_class, options)
        @association_name  = association_name.to_s
        @owner_class       = owner_class
        @target_class_name = options[:class_name] || association_name.to_s.camelize 
        @options           = options

        define_methods!
      end
      
      def define_methods!
        @owner_class.class_eval <<-eos
          def #{@association_name}
            @_#{@association_name} ||= self.class.associations[:#{@association_name}].find(self)
          end
          
          def #{@association_name}=(record)
            @_#{@association_name} = record
            self.class.associations[:#{@association_name}].set(self, record)
          end
        eos
      end
      
      def clear(owner)
        connection.remove(column_family, owner.key, @association_name)
      end
      
      def find(owner)
        if key = connection.get(column_family, owner.key, @association_name.to_s, nil, -1, 1).keys.first
          target_class.get(key)
        else
          nil
        end
      end  
      
      def set(owner, record, set_inverse = true)
        clear(owner)
        connection.insert(column_family, owner.key, {@association_name=>{record.key=>nil}})
        if has_inverse? && set_inverse
          inverse.set_inverse(record, owner)
        end
      end
      
      def set_inverse(owner, record)
        set(owner, record, false)
      end
      
      def has_inverse?
        @options[:inverse_of]
      end
      
      def inverse
        has_inverse? && target_class.associations[@options[:inverse_of]]
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
        # OneToManyAssociationProxy.new(self, owner)
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
        
    module ClassMethods
      
      def association(association_name, options= {})
        if options[:unique]
          associations[association_name] = OneToOneAssociation.new(association_name, self, options)
        else
          associations[association_name] = OneToManyAssociation.new(association_name, self, options)
        end
      end
    end
  end
end
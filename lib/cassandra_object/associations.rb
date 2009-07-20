module CassandraObject
  module Associations
    extend ActiveSupport::Concern
    
    included do
      class_inheritable_accessor :associations
      self.associations = ActiveSupport::OrderedHash.new
    end
    
    class OneToManyAssociation
      def initialize(association_name, owner_class, target_class_name)
        @association_name  = association_name.to_s
        @owner_class       = owner_class
        @target_class_name = target_class_name
        define_methods!
      end
      
      def find(owner)
        ids = connection.get(column_family, owner.id, @association_name)
        ids.keys.map {|id| target_class.get(id) }
      end
      
      def add(owner, record)
        connection.insert(column_family, owner.id, {@association_name=>{record.id=>nil}})
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
      
      def define_methods!
        @owner_class.class_eval <<-eos
          def #{@association_name}
            @_#{@association_name} ||= self.class.associations[:#{@association_name}].new_proxy(self)
          end
        eos
      end
    end
    
    class OneToOneAssociation
      def initialize(association_name, owner_class, target_class_name)
        @association_name  = association_name.to_s
        @owner_class       = owner_class
        @target_class_name = target_class_name
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
        connection.remove(column_family, owner.id, @association_name)
      end
      
      def find(owner)
        if id = connection.get(column_family, owner.id, @association_name.to_s, nil, -1, 1).keys.first
          target_class.get(id)
        else
          nil
        end
      end  
      
      def set(owner, record)
        clear(owner)
        connection.insert(column_family, owner.id, {@association_name=>{record.id=>nil}})
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
          target_class_name = options[:class_name] || association_name.to_s.camelize
          associations[association_name] = OneToOneAssociation.new(association_name, self, target_class_name)
        else
          target_class_name = options[:class_name] || association_name.to_s.singularize.camelize
          associations[association_name] = OneToManyAssociation.new(association_name, self, target_class_name)
        end
      end
    end
  end
end
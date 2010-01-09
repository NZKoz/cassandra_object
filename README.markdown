# Cassandra Object

Cassandra Object provides a nice API for working with [Cassandra](http://incubator.apache.org/cassandra/). CassandraObjects are mostly duck-type compatible with ActiveRecord objects so most of your controller code should work ok.  Note that they're *mostly* compatible, Cassandra has no support for dynamic queries, or sorting.  So the following kinds of operations aren't supported and *never will be*.

* `:order`
* `:conditions`
* `:joins`
* `:group`

There isn't much in the way of documentation yet, but a few examples.

        class Customer < CassandraObject::Base
          attribute :first_name,    :type => :string
          attribute :last_name,     :type => :string
          attribute :date_of_birth, :type => :date
          attribute :signed_up_at,  :type => :time_with_zone
    
          validate :should_be_cool
    
          key :uuid
  
          index :date_of_birth
  
          association :invoices, :unique=>false, :inverse_of=>:customer

          private
  
          def should_be_cool
            unless ["Michael", "Anika", "Evan", "James"].include?(first_name)
              errors.add(:first_name, "must be that of a cool person")
            end
          end
        end

        class Invoice < CassandraObject::Base
          attribute :number, :type=>:integer
          attribute :total, :type=>:float
          attribute :gst_number, :type=>:string
  
          # indexes can have a single entry also.
          index :number, :unique=>true
  
          # bi-directional associations with read-repair support.
          association :customer, :unique=>true, :inverse_of=>:invoices
  
          # Read migration support
          migrate 1 do |attrs|
            attrs["total"] ||= rand(2000) / 100.0
          end
  
          migrate 2 do |attrs|
            attrs["gst_number"] = "66-666-666"
          end
  
          key :natural, :attributes => :number
        end
        
        @invoice = Invoice.get("12345")
        @invoice.customer.invoices.all.include?(@invoice) # true
        
# FAQ

## How do I make this work?

Here are some basic directions:

  1. `git clone git://github.com/NZKoz/cassandra_object.git`
  2. Run the bundler `gem bundle`
  3. Make sure the tests pass `rake test`

This gem has backwards compatibility with active support version 2.3.x,  this is to enable people to use it with rails 2.3 applications.  This backwards compatibility may not continue after the 1.0 release.

## Should I use this in production?

Only if you're looking to help out with the development, there are a bunch of rough edges right now.

## Why do you use a superclass and not a module.

Because.

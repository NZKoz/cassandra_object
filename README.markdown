Provides a nice API for cassandra backed storage.  Because I'm too lazy to write docs for something so new, here is an example:

        class Customer < CassandraObject::Base
          attribute :first_name,    :type => String
          attribute :last_name,     :type => String
          attribute :date_of_birth, :type => Date
  
          validate :should_be_cool

          key :uuid
  
          index :last_name
  
          association :invoices, :unique=>false, :inverse_of=>:customer

          private
  
          def should_be_cool
            unless ["Michael", "Anika", "Evan", "James"].include?(first_name)
              errors.add(:first_name, "must be that of a cool person")
            end
          end


        end

        class Invoice < CassandraObject::Base
          attribute :number, :type=>Integer
          attribute :total, :type=>Float
          attribute :gst_number, :type=>String
  
          index :number, :unique=>true
  
          association :customer, :unique=>true, :inverse_of=>:invoices
  
          migrate 1 do |attrs|
            attrs["total"] ||= rand(2000) / 100.0
          end
  
          migrate 2 do |attrs|
            attrs["gst_number"] = "66-666-666"
          end
  
          key do
            ActiveSupport::SecureRandom.hex(64)
          end
        end
        
FAQ
===

# How do I make this work?

Here are some basic directions:

  1. Clone Evan Weaver's cassandra gem repository: `git clone git://github.com/fauna/cassandra.git`
  2. `sudo gem install echoe`
  3. `rake cassandra`
  4. `git clone git://github.com/NZKoz/cassandra_object.git`
  5. You can now drop into irb, and require 'cassandra_object/lib/cassandra_object'
  6. CassandraObject::Base.establish_connection "Twitter"
  7. Create a class that inherits from CassandraObject::Base
    8.1. Note that you'll need to modify storage-conf.xml in the cassandra repository you cloned in step #1 if you want to change the column families or anything.

Sorry, it's hard right now.  If you can't figure it out you should ask nzkoz for help on #cassandra on freenode.

You need to have a checkout of edge rails in ../rails if you want to run the tests.

# Should I use this in production?

Only if you're looking to help out with the development, there are a bunch of rough edges right now.


$: << 'lib'

RAILS_MASTER_DIR = ENV['EDGE_RAILS'] || "/Users/michaelkoziarski/OpenSource/rails"

$: << File.join(RAILS_MASTER_DIR, 'activemodel', 'lib')
$: << File.join(RAILS_MASTER_DIR, 'activesupport', 'lib')
require 'active_model'
require 'active_support/all'
require 'cassandra_object/base'
require 'pp'

# Assumes a storage config with this:
# 
# <Table Name="KozSandra">
#   <ColumnFamily ColumnSort="Name" Name="Customers" />
# </Table>



CassandraObject::Base.establish_connection "KozSandra"


class Customer < CassandraObject::Base
  attribute :first_name,    :type => String
  attribute :last_name,     :type => String
  attribute :date_of_birth, :type => Date
  
  validate :should_be_cool

  key :uuid

  private
  
  def should_be_cool
    unless ["Michael", "Anika"].include?(first_name)
      errors.add(:first_name, "must be that of a cool person")
    end
  end


end

class Invoice < CassandraObject::Base
  attribute :number, :type=>Integer
  
  key do
    ActiveSupport::SecureRandom.hex(64)
  end
end

# c = Customer.create! :first_name=>"Michael", :last_name=>"Koziarski", :date_of_birth=>28.years.ago.to_date
# 
# client = CassandraObject::Base.connection
# pp client.get_key_range("Customer")

# 
# client.insert(:Customers, "1", "first_name"=>"Michael", "last_name"=>"Koziarski", "date_of_birth"=>"1980-08-15")
# 
pp cust = Customer.get("1")

pp cust.first_name

cust.first_name="Michael"
cust.save
# 

# pp Customer.create(:first_name=>"Anika", :last_name=>"Koziarski", :date_of_birth=>Date.parse("1979-12-31"))

pp Invoice.create(:number=>Time.now.to_i)


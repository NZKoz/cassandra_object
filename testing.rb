$: << 'lib'
require 'rubygems'
require 'activesupport'
require 'cassandra_object/base'
require 'pp'

CassandraObject::Base.establish_connection "KozSandra"


class Customer < CassandraObject::Base
  attribute :first_name,    :type=>String
  attribute :last_name,     :type=>String
  attribute :date_of_birth, :type=>Date
end

# c = Customer.create! :first_name=>"Michael", :last_name=>"Koziarski", :date_of_birth=>28.years.ago.to_date
# 
# client = CassandraObject::Base.connection
# pp client.get_key_range("Customer")

# 
# client.insert(:Customers, "1", "first_name"=>"Michael", "last_name"=>"Koziarski", "date_of_birth"=>"1980-08-15")
# 
# pp cust = Customer.get("1")
# 
# pp cust.first_name
# 
# cust.first_name="Michael"
# cust.save
# 
# pp Customer.create(:first_name=>"Anika", :last_name=>"Koziarski", :date_of_birth=>Date.parse("1979-12-31"))

pp Customer.all

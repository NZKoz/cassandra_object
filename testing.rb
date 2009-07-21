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
#   <ColumnFamily ColumnType="Super" ColumnSort="Name" Name="CustomerRelationships" />
#   <ColumnFamily ColumnSort="Name" Name="Invoices" />
#   <ColumnFamily ColumnType="Super" ColumnSort="Name" Name="InvoiceIndexes" />
#   <ColumnFamily ColumnSort="Name" Name="InvoicesByNumber" />
# </Table>




CassandraObject::Base.establish_connection "KozSandra"


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
    unless ["Michael", "Anika", "Evan"].include?(first_name)
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
    attrs["gst_number"] = "68-091-985"
  end
  
  key do
    ActiveSupport::SecureRandom.hex(64)
  end
end

# c = Customer.create! :first_name=>"Michael", :last_name=>"Koziarski", :date_of_birth=>28.years.ago.to_date
# 
client = CassandraObject::Base.connection
# pp client.get_key_range("Customer")

# 
# client.insert(:CustomerRelationships, "1", "invoices"=>{Invoice.first.key=>nil})
# # 
# pp cust = Customer.first
# 
# pp cust.first_name
# 
# cust.first_name="Michael"
# cust.save
# 
# pp cust.to_json
# 
# # pp Customer.create(:first_name=>"Anika", :last_name=>"Koziarski", :date_of_birth=>Date.parse("1979-12-31"))
# pp i = Invoice.create(:number=>Time.now.to_i)
# 
# pp Invoice.find_by_number(i.number)
# 
# pp Customer.create(:first_name=>"Evan", :last_name=>"Weaver")
# 
# pp Customer.find_all_by_last_name("Weaver")


# ["Hello I am not a date", Date.today, "1980-08-15"].each do |dob|
#   pp "Trying #{dob.inspect}"
#   c = Customer.new(:date_of_birth=>dob, :first_name=>"Michael")
#   pp c.valid?
#   pp c.errors
# end

# ["I'm not an int", 1, "1", "-11"].each do |n|
#   pp "trying #{n.inspect}"
#   i = Invoice.new(:number=>n)
#   i.valid?
#   pp i.errors
# end

 i = Invoice.first
 i.valid?
 pp i
 i.save


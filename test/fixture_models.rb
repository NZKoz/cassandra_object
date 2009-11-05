
class Customer < CassandraObject::Base
  attribute :first_name,    :type => String
  attribute :last_name,     :type => String
  attribute :date_of_birth, :type => Date
  attribute :preferences,   :type => Hash
  
  validate :should_be_cool

  key :uuid
  
  index :last_name, :reversed=>true
  
  association :invoices, :unique=>false, :inverse_of=>:customer, :reversed=>true

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
    attrs["total"] ||= (rand(2000) / 100.0).to_s
  end
  
  migrate 2 do |attrs|
    attrs["gst_number"] = "66-666-666"
  end
  
  key :uuid
end

class Payment < CassandraObject::Base
  attribute :reference_number, :type => String
  attribute :amount,           :type => Integer

  key :natural, :attributes => :reference_number
end

MockRecord = Struct.new(:key)

class Person < CassandraObject::Base
  attribute :name, :type => String
  attribute :age,  :type => Integer
end

class Appointment < CassandraObject::Base
  attribute :title,      :type => String
  attribute :start_time, :type => Time
  attribute :end_time,   :type => Time, :allow_nil => true
  
  key :natural, :attributes => :title
end
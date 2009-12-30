

module ReverseStringStorage
  def self.parse(string)
    string.reverse
  end
  
  def self.serialize(value)
    value.to_s.reverse
  end
  
  def self.append_validation(type)
    
  end
  
  def self.format
    nil
  end
  
  def self.expected_type
    String
  end
end


class Customer < CassandraObject::Base
  attribute :first_name,     :type => :string
  attribute :last_name,      :type => :string
  attribute :date_of_birth,  :type => :date
  attribute :preferences,    :type => :hash
  attribute :custom_storage, :type => ReverseStringStorage
  
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
  attribute :number,     :type=>:integer
  attribute :total,      :type=>:float
  attribute :gst_number, :type=>:string
  
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
  attribute :reference_number,  :type => :string
  attribute :amount,            :type => :float
  attribute :unique_identifier, :type=> :uuid, :allow_nil=>true

  key :natural, :attributes => :reference_number
end

MockRecord = Struct.new(:key)

class Person < CassandraObject::Base
  attribute :name, :type => :string
  attribute :age,  :type => :integer
end

class Appointment < CassandraObject::Base
  attribute :title,      :type => :string
  attribute :start_time, :type => :time
  attribute :end_time,   :type => :time_with_zone, :allow_nil => true
  
  key :natural, :attributes => :title
end
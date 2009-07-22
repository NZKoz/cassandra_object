
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
    attrs["gst_number"] = "66-666-666"
  end
  
  key do
    ActiveSupport::SecureRandom.hex(64)
  end
end

MockRecord = Struct.new(:key)
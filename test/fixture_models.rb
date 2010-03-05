module ReverseStorage
  def encode(str)
    str.reverse
  end
  module_function :encode

  def decode(str)
    str.reverse
  end
  module_function :decode
end


class Customer < CassandraObject::Base
  attribute :first_name,     :type => :string
  attribute :last_name,      :type => :string
  attribute :date_of_birth,  :type => :date
  attribute :preferences,    :type => :hash
  attribute :custom_storage, :type => String, :converter=>ReverseStorage

  validate :should_be_cool
  validates_presence_of :last_name

  after_create :set_after_create_called

  key :uuid

  index :last_name, :reversed=>true

  association :invoices, :unique=>false, :inverse_of=>:customer, :reversed=>true
  association :paid_invoices, :unique=>false, :class_name=>'Invoice'

  def after_create_called?
    @after_create_called
  end

  def set_after_create_called
    @after_create_called = true
  end

  private

  def should_be_cool
    unless ["Michael", "Anika", "Evan", "Tom"].include?(first_name)
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
  attribute :reference_number, :type => :string
  attribute :amount,           :type => :integer

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
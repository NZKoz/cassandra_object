require 'test_helper'

class IndexTest < CassandraObjectTestCase
  context "A non-unique index" do
    setup do
      @last_name = ActiveSupport::SecureRandom.hex(5)
      @koz = Customer.create :first_name=>"Michael", :last_name=>@last_name, :date_of_birth=>28.years.ago.to_date
      @wife = Customer.create :first_name=>"Anika", :last_name=>@last_name, :date_of_birth=>30.years.ago.to_date
    end
    
    should "Return both values" do
      assert_equal [@wife, @koz], Customer.find_all_by_last_name(@last_name)
    end
  end
  
  context "A unique index" do
    setup do
      @invoice = mock_invoice
      @number = @invoice.number
    end
    
    should "return the right record" do
      assert_equal @invoice, Invoice.find_by_number(@number)
    end
    
    should "return nil after destroy" do
      @invoice.destroy
      assert_nil Invoice.find_by_number(@number)
    end
  end
end
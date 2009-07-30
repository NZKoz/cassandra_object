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
    
    should "return the older when the newer is destroyed" do
      @wife.destroy
      assert_equal [@koz], Customer.find_all_by_last_name(@last_name)
    end
  end

  context "A corrupt non-unique index" do
    setup do
      @last_name = ActiveSupport::SecureRandom.hex(5)
      @koz = Customer.create :first_name=>"Michael", :last_name=>@last_name, :date_of_birth=>28.years.ago.to_date
      connection.insert("CustomersByLastName", @last_name, {"last_name"=>{"ROFLSKATES"=>nil}})
      @wife = Customer.create :first_name=>"Anika", :last_name=>@last_name, :date_of_birth=>30.years.ago.to_date
    end
    
    should "Return both values and clean up" do
      assert_equal [@wife, @koz], Customer.find_all_by_last_name(@last_name)
      assert_equal [@wife.key, @koz.key], connection.get("CustomersByLastName", @last_name, "last_name").keys
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
  
  context " A corrupt unique index" do
    setup do
      connection.insert("InvoicesByNumber", '15' , {"number"=>{"key"=>"HAHAHAHA"}})
    end
    
    should "return nil on fetch and cleanup" do
      assert_nil Invoice.find_by_number(15)
      assert connection.get("InvoicesByNumber", "15", "number").blank?
    end
    
  end
end
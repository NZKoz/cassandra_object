require 'test_helper'

class IndexTest < CassandraObjectTestCase
  context "A non-unique index" do
    setup do
      @last_name = ActiveSupport::SecureRandom.hex(5)
      @koz = Customer.create :first_name=>"Michael", :last_name=>@last_name, :date_of_birth=>28.years.ago.to_date
      @wife = Customer.create :first_name=>"Anika", :last_name=>@last_name, :date_of_birth=>30.years.ago.to_date
    end
    
    should "Return both values" do
      assert_ordered [@wife.key, @koz.key], Customer.find_all_by_last_name(@last_name).map(&:key)
    end
    
    should "return the older when the newer is destroyed" do
      @wife.destroy
      assert_equal [@koz.key], Customer.find_all_by_last_name(@last_name).map(&:key)
    end
    
    should "return a single value when the original one is changed" do
      @wife.last_name = "WTF"
      @wife.save
      assert_equal [@koz.key], Customer.find_all_by_last_name(@last_name).map(&:key)
    end
  end

  context "A corrupt non-unique index" do
    setup do
      @last_name = ActiveSupport::SecureRandom.hex(5)
      @koz = Customer.create :first_name=>"Michael", :last_name=>@last_name, :date_of_birth=>28.years.ago.to_date
      connection.insert("CustomersByLastName", @last_name, {"last_name"=>{Cassandra::UUID.new=>"ROFLSKATES"}})
      @wife = Customer.create :first_name=>"Anika", :last_name=>@last_name, :date_of_birth=>30.years.ago.to_date
    end
    
    should "Return both values and clean up" do
      assert_ordered [@wife.key, @koz.key], Customer.find_all_by_last_name(@last_name).map(&:key)
      assert_ordered [@wife.key, @koz.key], connection.get("CustomersByLastName", @last_name, "last_name", :reversed=>true).values
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
      connection.insert("InvoicesByNumber", '15' , {"key"=>"HAHAHAHA"})
    end
    
    should "return nil on fetch and cleanup" do
      assert_nil Invoice.find_by_number(15)
      assert connection.get("InvoicesByNumber", "15", "number").blank?
    end
    
  end
end
require 'test_helper'

class TimeTest < CassandraObjectTestCase

  test "new raises an error" do
    begin
      appt = Appointment.new :start_time => 1
      flunk "Should have failed to save"
    rescue TypeError => e
      assert_equal "Expected Time but got 1", e.message
    end
  end

  test "the attribute writer raises an error" do
    begin
      appt = Appointment.new
      appt.start_time = 1
      flunk "Should have failed to save"
    rescue TypeError => e
      assert_equal "Expected Time but got 1", e.message
    end
  end

  test "Time's should be round-trip-able" do
    appt = Appointment.new :start_time => (t = Time.now.utc), :title => "team meeting"
    appt.save!
    appt2 = Appointment.get(appt.key)

    assert_equal appt.start_time.class, appt2.start_time.class
    assert_equal appt.start_time.to_i,       appt2.start_time.to_i
  end
end
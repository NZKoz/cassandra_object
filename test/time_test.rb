require 'test_helper'

class TimeTest < CassandraObjectTestCase

  test "new raises an error" do
    begin
      appt = Appointment.new :start_time => 1
      flunk "Should have failed to save"
    rescue ArgumentError => e
      assert_equal "CassandraObject::TimeType requires a Time", e.message
    end
  end

  test "the attribute writer raises an error" do
    begin
      appt = Appointment.new
      appt.start_time = 1
      flunk "Should have failed to save"
    rescue ArgumentError => e
      assert_equal "CassandraObject::TimeType requires a Time", e.message
    end
  end

  test "Time's should be round-trip-able" do
    appt = Appointment.new :start_time => (t = Time.now.utc), :title => "team meeting"
    appt.save!
    appt2 = Appointment.get(appt.key)

    assert_equal appt.start_time.class, appt2.start_time.class
    assert_equal appt.start_time,       appt2.start_time
  end
end

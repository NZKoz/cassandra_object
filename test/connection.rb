ENV['CASSANDRA'] ||= "/usr/local/cassandra/bin/cassandra"

if ENV['CASSANDRA_REQUIRED']
  tmp = File.expand_path(File.join(File.dirname(__FILE__), '..', 'tmp'))
  config = File.expand_path(File.join(File.dirname(__FILE__), 'config'))

  $pid = fork {
    Dir.chdir(tmp)
    puts "CASSANDRA_INCLUDE=#{config}/cassandra.in.sh #{ENV['CASSANDRA']} -f"
  }

  # Wait for cassandra to boot
  sleep 3
end

puts "Connecting..."
CassandraObject::Base.establish_connection "CassandraObject"

if defined?($pid)
  at_exit do
    puts "Shutting down Cassandra..."
    Process.kill('INT', $pid)
    Process.wait($pid)
  end
end

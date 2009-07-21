CASSANDRA_BIN = File.expand_path(ENV['CASSANDRA'] || "../cassandra-r789419/bin/cassandra")
CASSANDRA_CONF = File.expand_path(File.join(File.dirname(__FILE__), 'config'))
TMP_DIR = File.join(File.dirname(__FILE__), '..', 'tmp')

$pid = fork {
  Dir.chdir(TMP_DIR)
  exec "JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home \
    PATH=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home/bin:$PATH \
    CASSANDRA_CONF=#{CASSANDRA_CONF} \
    CASSANDRA_INCLUDE=#{CASSANDRA_CONF}/cassandra.in.sh \
    #{CASSANDRA_BIN} -f"
}

# Wait for cassandra to boot
sleep 3

puts "Connecting..."
CassandraObject::Base.establish_connection "CassandraObject"

at_exit do
  puts "Shutting down Cassandra..."
  Process.kill('INT', $pid)
  Process.wait($pid)
end

dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << dir unless $LOAD_PATH.include?(dir)

require 'cassandra_object/base'

module CassandraObject
end


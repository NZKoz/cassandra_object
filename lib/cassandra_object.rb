dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << dir unless $LOAD_PATH.include?(dir)
vendor = File.expand_path(File.dirname(__FILE__) + "/../vendor")
$LOAD_PATH << vendor + "/activemodel/lib"

require 'activesupport'
require 'cassandra_object/base'

module CassandraObject
end


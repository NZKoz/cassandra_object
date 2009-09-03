dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << dir unless $LOAD_PATH.include?(dir)
vendor = File.expand_path(File.dirname(__FILE__) + "/../vendor")
$LOAD_PATH << vendor + "/activemodel/lib"
$LOAD_PATH << vendor + "/activesupport/lib"

require 'activesupport'
require 'activemodel'
require 'json'
require 'active_support/concern'
require 'cassandra_object/base'

module CassandraObject
end


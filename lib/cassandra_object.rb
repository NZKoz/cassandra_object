dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << dir unless $LOAD_PATH.include?(dir)
vendor = File.expand_path(File.dirname(__FILE__) + "/../vendor")
$LOAD_PATH << vendor + "/activemodel/lib"
$LOAD_PATH << vendor + "/activesupport/lib"

require 'i18n'
require 'active_support'
require 'active_support/all'
require 'active_model'
require 'cassandra_object/base'

module CassandraObject
end


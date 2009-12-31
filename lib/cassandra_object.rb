dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << dir unless $LOAD_PATH.include?(dir)
vendor = File.expand_path(File.dirname(__FILE__) + "/../vendor")
$LOAD_PATH << vendor + "/activemodel/lib"
$LOAD_PATH << vendor + "/activesupport/lib"

require 'i18n'
require 'active_support'
require 'active_model'
require 'active_support/concern'
require 'active_support/time_with_zone'
require 'cassandra_object/base'
require 'active_support/core_ext/array/wrap'

module CassandraObject
end


dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << dir unless $LOAD_PATH.include?(dir)

# TODO: This won't be necessary when we can expect to load the dependencies from gems
rails_source_root = File.expand_path("../rails")
if File.directory?(rails_source_root)
  $LOAD_PATH << rails_source_root + "/activesupport/lib"
  require "active_support/all"

  $LOAD_PATH << rails_source_root + "/activemodel/lib"
  require "active_model"
end

require 'cassandra_object/base'

module CassandraObject
end


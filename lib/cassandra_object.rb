require 'rubygems'
require 'i18n'
require 'active_support'
require 'active_support/version'

module CassandraObject
  class << self
    attr_accessor :old_active_support
  end
  self.old_active_support = false
  VERSION = "0.5.0"
end


if ActiveSupport::VERSION::STRING =~ /^2/
  
  vendor = File.expand_path(File.dirname(__FILE__) + "/../vendor")
  CassandraObject.old_active_support = true
  $LOAD_PATH << vendor
  require 'active_support_shims'
  $LOAD_PATH << vendor + "/activemodel/lib"
  require 'active_model'
else
  require 'active_support/all'
  require 'active_model'
end

require 'cassandra_object/base'



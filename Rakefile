require 'rubygems'
require 'rake'
require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "cassandra_object"
    s.summary = "ORM for interacting with Cassandra."
    s.email = ""
    s.homepage = ""
    s.description = ""
    s.authors = ["Michael Koziarski"]
    file_list = FileList.new("[A-Z]*.*", "{bin,generators,lib,test,spec,rails,vendor}/**/*") do |f|
    end
    s.files = file_list
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'yard'
YARD::Rake::YardocTask.new(:yard)

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files=Dir.glob( "test/**/*_test.rb" ).sort
  t.verbose = true
end

task :cleanup do
  unless defined?(CassandraObject)
    $: << 'test'
    $: << 'lib'
    require 'test_helper'
  end
  puts "Clearing keyspace! ..."
  CassandraObject::Base.connection.clear_keyspace!
  puts "Cleared"
end

task :default=>[:test, :cleanup] do
end


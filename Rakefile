require 'rubygems'
require 'rake'
require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "cassandra_object"
    s.summary = "Maps your objects into cassandra."
    s.email = "michael@koziarski.com"
    s.homepage = "http://github.com/NZKoz/cassandra_object"
    s.description = "Gives you most of the familiarity of ActiveRecord, but with the scalability of cassandra."
    s.authors = ["Michael Koziarski"]
    file_list = FileList.new("[A-Z]*.*", "{bin,generators,lib,test,spec,rails,vendor}/**/*") do |f|
    end
    s.files = file_list
    s.add_dependency('activesupport', '>= 3.0.pre')
    s.add_dependency('activemodel',   '>= 3.0.pre')
    
  end
  Jeweler::GemcutterTasks.new
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


require 'rubygems'
require 'rake'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files=Dir.glob( "test/**/*_test.rb" ).sort
  t.verbose = true
end

Rake::TestTask.new(:legacy_test) do |t|
  t.libs << "test/legacy"
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


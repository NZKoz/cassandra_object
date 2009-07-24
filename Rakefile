require 'rubygems'
require 'rake'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files=Dir.glob( "test/**/*_test.rb" ).sort
  t.verbose = true
end

task :cleanup do
  CassandraObject::Base.connection.clear_keyspace!
end

task :default=>[:test, :cleanup] do
end


# Rake require.
require "rake/testtask"

# Require the bookmark site app and the deployment module.
require_relative "bookmark-site.rb"
require_relative "ruby-scripts/deployment-scripts.rb"
require_relative "ruby-scripts/test_deletes.rb"
require_relative "ruby-scripts/test_deployment_scripts.rb"
require_relative "ruby-scripts/test_support_functions.rb"
require_relative "ruby-scripts/test_updates.rb"

desc "Cleans the database of all data."
task :wipedb do
  puts "Wiping the database"
  Deployment.resetDatabase
  puts "Wipe complete"
end

desc "Adds the basic config data to the database"
task :resetdb => :wipedb do

end

desc "Sets up database for testing with cucumber"
task :testdb => :wipedb do
    puts "Adding test data to database"
    Deployment.testData
    puts "Test data added"
end

desc "Lauch with test data."
task :testrun => :testdb do
  Sinatra::Application.run!
end

desc "Run the Sinatra app locally"
task :run do
  Sinatra::Application.run!
end

desc "Run the unit tests"
task :unittest do
    #:testdb
    #ruby "ruby-scripts/test_database.rb"
    :testdb
    ruby "ruby-scripts/test_deletes.rb"
    :testdb
    ruby "ruby-scripts/test_deployment_scripts.rb"
    :testdb
    ruby "ruby-scripts/test_support_functions.rb"
    :testdb
    ruby "ruby-scripts/test_updates.rb"
end

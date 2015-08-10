require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rubygems/package_task'
require 'rspec/core/rake_task'
require 'spree/core/testing_support/common_rake'
require 'spree/api'

RSpec::Core::RakeTask.new

task :default => :spec

spec = eval(File.read('spree_reservebar_api.gemspec'))

Gem::PackageTask.new(spec) do |p|
  p.gem_spec = spec
end

desc "Generates a dummy app for testing"
task :test_app do
  ENV['LIB_NAME'] = 'spree/api'
  Rake::Task['common:test_app'].invoke
end

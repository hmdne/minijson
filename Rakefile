require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:rspec)

require 'opal/rspec/rake_task'
Opal::RSpec::RakeTask.new(:"rspec-opal") do |_, task|
  require 'opal'
  Opal.append_path File.expand_path('../lib', __FILE__)

  task.default_path = 'spec'
  task.pattern = 'spec/**/*_spec.{rb,opal}'
  # ENV['SPEC_OPTS'] ||= "--format documentation --color"
end

task :spec => [:rspec, :"rspec-opal"]
task :default => :spec

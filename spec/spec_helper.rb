require "bundler/setup"
require "minijson"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :should
  end
end

def parse(str)
  MiniJSON.parse(str)
end
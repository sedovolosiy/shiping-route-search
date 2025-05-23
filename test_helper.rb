require 'pry-byebug'
require 'simplecov'

# Only start SimpleCov if COVERAGE environment variable is set to 'true'
if ENV['COVERAGE'] == 'true'
  SimpleCov.start do
  # Don't run coverage on test files
  add_filter do |source_file|
    source_file.filename.include?('/test_') || source_file.filename.end_with?('_test.rb')
  end
  # Track all application code
  track_files "application/**/*.rb"
  track_files "domain/**/*.rb"
  track_files "infrastructure/**/*.rb"
  
  # Group files by component
  add_group 'Application', 'application'
  add_group 'Domain', 'domain'
  add_group 'Infrastructure', 'infrastructure'
  
  # Enable branch coverage
  enable_coverage :branch
  end
end

require 'minitest/autorun'
require 'stringio'
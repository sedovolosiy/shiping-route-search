require 'rake/testtask'
require 'dotenv/load' # Load environment variables from .env file

Rake::TestTask.new(:test) do |t|
  # ENV['COVERAGE'] is now loaded from .env file
  t.libs << '.'
  t.warning = false
  t.verbose = true
  # Include both patterns to ensure all tests are run
  t.pattern = [
    'tests/**/test_*.rb', 
    'tests/test_*.rb'
  ]
end

desc "Run tests with coverage and open the report"
task :coverage => :test do
  puts "\nOpening coverage report..."
  if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    system "start coverage/index.html"
  elsif RbConfig::CONFIG['host_os'] =~ /darwin/
    system "open coverage/index.html"
  elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
    system "xdg-open coverage/index.html"
  end
end

task default: :test

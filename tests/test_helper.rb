require 'simplecov'
SimpleCov.start do
  add_filter '/tests/'
  track_files 'application/**/*.rb'
end

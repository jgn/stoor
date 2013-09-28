require 'rspec/core/rake_task'

desc 'Default: run the specs.'
task :default => [:spec]

desc 'Test the stoor gem.'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ['--color', "--format progress"]
  t.pattern = 'spec/**/*_spec.rb'
end

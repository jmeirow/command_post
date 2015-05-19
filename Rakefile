require "bundler/gem_tasks"
require "rake/testtask"

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['spec/command_post/*_spec.rb', 'spec/command_post/*/*_spec.rb']
  t.verbose = true
end

require 'rake/testtask'

task default: :help

Rake::TestTask.new do |t|
  t.libs << 'lib/rack'
  t.test_files = FileList['test/test_*.rb']
end

desc 'Print available rake tasks'
task :help do
  system 'bundle exec rake -T'
end

desc 'Run the rack app'
task :serve do
  system 'bundle exec rackup -s Thin -p 9292'
end

desc 'Rebuild the gem'
task :rebuild do
  system 'rm rack-jsonparser-*.gem'
  system 'gem build rack-jsonparser.gemspec'
end

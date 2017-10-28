require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib/rack'
  t.test_files = FileList['test/test_*.rb']
end

task default: :test

desc 'Run the web app'
task :serve do
  system 'rackup -s Thin -p 9292'
end

desc 'Rebuild the gem'
task :rebuild do
  system 'rm rack-jsonparser-*.gem'
  system 'gem build rack-jsonparser.gemspec'
end

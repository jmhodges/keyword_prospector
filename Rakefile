require 'config/requirements'
require 'config/hoe' # setup Hoe + all gem configuration

Dir['tasks/**/*.rake'].each { |rake| load rake }

# Make spec the default task, instead of test.
Rake::Task[:default].prerequisites.clear
task :default => :spec
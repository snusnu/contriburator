$LOAD_PATH.unshift(File.expand_path('../app/', __FILE__))
$LOAD_PATH.unshift(File.expand_path('../lib',  __FILE__))

require 'rake'
require 'service/config'
require 'service/models'

log_stream = ENV['DM_LOG']
log_level  = ENV['DM_LOG_LEVEL'] || :debug

namespace :db do

  desc "Auto-upgrade the database"
  task :autoupgrade do
    Contriburator::Config::Persistence.auto_upgrade!(log_stream, log_level)
  end

  desc "Auto-migrate the database"
  task :automigrate do
    Contriburator::Config::Persistence.auto_migrate!(log_stream, log_level)
  end

  desc "Import necessary seed data"
  task :seed => :automigrate do
    Contriburator::Persistence::Language.create :code => 'en-US', :name => 'English (USA)'
  end

end

require 'brewery'
load 'brewery/tasks/brewery.rake'

require 'jasmine'
load 'jasmine/tasks/jasmine.rake'

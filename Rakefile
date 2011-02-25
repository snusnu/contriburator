$LOAD_PATH.unshift(File.expand_path('../service', __FILE__))

log_stream = ENV['DM_LOG']
log_level  = ENV['DM_LOG_LEVEL'] || :debug

desc "Generate a sample config.yml"
file "config/config.yml" => "config/config.yml.sample" do |t|
  sh "cp #{t.prerequisites.first} #{t.name}"
end

require 'config'
require 'models'

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

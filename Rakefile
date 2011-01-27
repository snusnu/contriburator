$LOAD_PATH.unshift(File.expand_path('../app', __FILE__))

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
    Contriburator::Persistence.setup(log_stream, log_level)
    DataMapper.auto_upgrade!
  end

  desc "Auto-migrate the database"
  task :automigrate do
    Contriburator::Persistence.setup(log_stream, log_level)
    DataMapper.auto_migrate!
  end

  desc "Import the initially available jobs"
  task :seed do
    Contriburator::Persistence.create(log_stream, log_level)

    # create the initial seed data
  end

end

$LOAD_PATH.unshift(File.expand_path('../service', __FILE__))
$LOAD_PATH.unshift(File.expand_path('../lib',     __FILE__))

require 'config'
require 'models'
require 'brewery'

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

namespace :build do

  desc "Compile coffee in 'public/app' to js in 'public/js'"
  task :brew do
    Brewery.brew
  end

  desc "Watch and compile coffee in 'public/app' to js in 'public/js' continuously"
  task :watch do
    Brewery.watch
  end

  desc "Combine and minify js libs (only in production env)"
  task :lib do
    Brewery.build_lib
  end

  desc "Compile coffeescripts (also combine and minify in production)"
  task :app do
    Brewery.build_app
  end

  desc "Same as running 'build:lib' followed by 'build:app'"
  task :all do
    Brewery.build_all
  end

end

$LOAD_PATH.unshift(File.expand_path('../lib',     __FILE__))
$LOAD_PATH.unshift(File.expand_path('../service', __FILE__))

require 'config'
require 'service'

log_stream = ENV['DM_LOG']
log_level  = ENV['DM_LOG_LEVEL'] || :debug

Contriburator::Config::Persistence.setup(log_stream, log_level)

require 'brewery' # build minified js in production env
Brewery.new.build_all if ENV['RACK_ENV'] == 'production'

use Rack::CommonLogger

run Contriburator::Server

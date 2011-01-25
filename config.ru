log_stream = ENV['DM_LOG']
log_level  = ENV['DM_LOG_LEVEL'] || :debug

$LOAD_PATH.unshift(File.expand_path('../app', __FILE__))

require 'config'
require 'server'

Contriburator::Persistence.setup(log_stream, log_level)

use Rack::CommonLogger

run Contriburator::Server

log_stream = ENV['DM_LOG']
log_level  = ENV['DM_LOG_LEVEL'] || :debug

$LOAD_PATH.unshift(File.expand_path('../service', __FILE__))

require 'config'
require 'service'

Contriburator::Config::Persistence.setup(log_stream, log_level)

use Rack::CommonLogger

run Contriburator::Server

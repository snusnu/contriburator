require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-transactions'
require 'dm-types'
require 'dm-serializer/to_json'

module Contriburator

  module Persistence

    class IdentityMap
      def initialize(app)
        @app = app
      end

      def call(env)
        DataMapper.repository { @app.call(env) }
      end
    end # class IdentityMap

    def self.setup(log_stream, log_level)
      setup_logger(log_stream, log_level) if log_stream

      convention = DataMapper::NamingConventions::Resource::UnderscoredAndPluralizedWithoutModule
      adapter    = DataMapper::setup(:default, Config['database'])
      adapter.resource_naming_convention = convention
      DataMapper.finalize

      adapter
    end

    def self.create(log_stream, log_level)
      setup(log_stream, log_level)
      DataMapper.auto_migrate!
    end

    def self.setup_logger(stream, level)
      DataMapper::Logger.new(log_stream(stream), level)
    end

    def self.log_stream(stream)
      stream == 'stdout' ? $stdout : stream
    end

  end # module Persistence
end # module Contriburator

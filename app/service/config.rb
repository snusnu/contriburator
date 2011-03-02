require 'pathname'
require 'yaml'

module Contriburator

  def self.root
    @root ||= Pathname(File.dirname(__FILE__))
  end

  module Config

    module Persistence

      def self.setup(log_stream, log_level)
        Connection.new(log_stream, log_level).setup
      end

      def self.auto_migrate!(log_stream, log_level)
        Connection.new(log_stream, log_level).auto_migrate!
      end

      def self.auto_upgrade!(log_stream, log_level)
        Connection.new(log_stream, log_level).auto_upgrade!
      end

      class Connection

        attr_reader :log_stream
        attr_reader :log_level

        def initialize(log_stream, log_level)
          @log_stream = (log_stream == 'stdout' ? $stdout : log_stream)
          @log_level  = log_level
        end

        def setup
          setup_logger if log_stream

          convention = DataMapper::NamingConventions::Resource::UnderscoredAndPluralizedWithoutModule
          adapter    = DataMapper::setup(:default, Config['database'])
          adapter.resource_naming_convention = convention
          DataMapper.finalize

          adapter
        end

        def auto_migrate!
          setup
          DataMapper.auto_migrate!
        end

        def auto_upgrade!
          setup
          DataMapper.auto_upgrade!
        end

      private

        def setup_logger
          DataMapper::Logger.new(log_stream, log_level)
        end

      end # class Connection

      class IdentityMap
        def initialize(app)
          @app = app
        end

        def call(env)
          DataMapper.repository { @app.call(env) }
        end
      end # class IdentityMap

    end # module Persistence

    def self.root
      @root ||= Contriburator.root.join('..')
    end

    def self.public_dir
      root.join('public')
    end

    def self.[](key)
      config[key]
    end

  private

    def self.config
      return @config if @config

      @config = YAML.load_file(root.join('service.yml'))
    end

  end # module Config
end # module Contriburator

require 'pathname'
require 'yaml'

module Contriburator

  def self.root
    @root ||= Pathname(File.dirname(__FILE__))
  end

  module Config

    def self.root
      @root ||= Contriburator.root.join('../config')
    end

    def self.[](key)
      config[key]
    end

  private

    def self.config
      return @config if @config

      @config = YAML.load_file(root.join('config.yml'))
    end

  end # module Config
end # module Contriburator

require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-transactions'
require 'dm-types'

require 'dm-is-localizable'
require 'dm-accepts_nested_attributes'

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

    class Language

      include DataMapper::Resource

      # properties

      property :id,   Serial

      property :code, String, :required => true, :unique => true, :format => /\A[a-z]{2}-[A-Z]{2}\z/
      property :name, String, :required => true

      def self.[](code)
        codes[code]
      end

      class << self
        private

        def codes
          @codes ||= Hash.new do |codes, code|
            codes[code] = first(:code => code.to_s.tr('_', '-')).freeze
          end
        end
      end

    end

    class Contributor

      include DataMapper::Resource

      property :id,         Serial

      property :name,       String
      property :company,    String
      property :homepage,   String, :length => 255
      property :email,      String
      property :twitter,    String
      property :irc,        String
      property :github,     String, :unique => true
      property :location,   String

      property :created_at, DateTime

      has n, :contributions

      has n, :projects,
        :through => :contributions

      def tweets?
        !twitter_name.nil?
      end

    end

    class Project

      class Relationship

        include DataMapper::Resource

        storage_names[:default] = 'project_relationships'

        belongs_to :client,     'Project', :key => true
        belongs_to :dependency, 'Project', :key => true

        is :localizable do
          
          property :description, Text
          property :created_at,  DateTime
          
        end
      end

      class Bounty

        class Status

          include DataMapper::Resource

          storage_names[:default] = 'bounty_states'

          property :name,        String, :key => true, :length => 20
          property :description, Text, :required => true

        end # class Status

        include DataMapper::Resource

        storage_names[:default] = 'project_bounties'

        property :id,          Serial
        property :goal,        Integer,  :required => true
        property :start_date,  DateTime, :required => true
        property :stop_date,   DateTime, :required => true

        is :localizable do

          property :description,     Text, :required => true

        end


        belongs_to :status, :child_key => [ :name ]

      end # class Bounty

      include DataMapper::Resource

      property :id,            Serial

      property :github_url,    String, :length => 255, :required => true, :unique => true

      property :homepage,      URI
      property :documentation, URI
      property :issues,        URI
      property :mailing_list,  URI
      property :twitter,       String, :length => (0..255)
      property :created_at,    DateTime

      is :localizable do

        property :description,     Text

      end


      belongs_to :parent, self, :required => false

      has n, :forks, self, :child_key => [:parent_id]

      has n, :project_dependencies, 'Contriburator::Project::Relationship',
        :child_key => [:client_id]

      has n, :dependencies, self,
        :through => :project_dependencies,
        :via     => :dependency

      has n, :client_projects, 'Contriburator::Project::Relationship',
        :child_key => [:dependency_id]

      has n, :clients, self,
        :through => :client_projects,
        :via     => :client

      has n, :contributions

      has n, :members, 'Contributor',
        :through => :contributions,
        :via     => :contributor

      has n, :bounties

      has n, :irc_channels, :through => Resource


      #accepts_nested_attributes_for :irc_channels


      def name
        @name ||= github_url.sub('http://github.com/', '')
      end

      def fork?
        !self.parent.nil?
      end

      def has_forks?
        !forks.empty?
      end

    end

    class IrcChannel

      include DataMapper::Resource

      property :id,         Serial

      property :server,     String,  :required => true, :unique => :unique_channels
      property :channel,    String,  :required => true, :unique => :unique_channels
      property :logged,     Boolean, :required => true, :default => false

      property :created_at, DateTime

      def raw_channel_name
        channel.gsub('#', '')
      end

    end

    class Contribution

      class Kind

        include DataMapper::Resource

        storage_names[:default] = 'contribution_kinds'

        property :name,        String, :key => true
        property :description, Text

      end

      include DataMapper::Resource

      belongs_to :project,     :key => true
      belongs_to :contributor, :key => true
      belongs_to :kind,        :key => true, :child_key => [:kind], :parent_key => [:name]

      property :anonymous, Boolean, :default => true

      # works

      def self.nr_of_forkers
        all(:fields => [ :person_id ], :kind => 'forker').map(&:person_id).uniq.size
      end

      def self.nr_of_watchers
        all(:fields => [ :person_id ], :kind => 'watcher').map(&:person_id).uniq.size
      end

      def self.nr_of_collaborators
        all(:fields => [ :person_id ], :kind => 'collaborator').map(&:person_id).uniq.size
      end

      def self.nr_of_contributors
        all(:fields => [ :person_id ], :kind => 'contributor').map(&:person_id).uniq.size
      end

      # TODO doesn't work

      def self.forkers
        all_of_kind('forker')
      end

      def self.watchers
        all_of_kind('watcher')
      end

      def self.collaborators
        all_of_kind('collaborator')
      end

      def self.contributors
        all_of_kind('contributor')
      end

      def self.all_of_kind(kind)
        all(:fields => [ :person_id ], :kind => kind, :unique => true).size
      end

    end

  end # module Persistence
end # module Contriburator

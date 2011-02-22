require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-transactions'
require 'dm-types'
require 'dm-zone-types'

require 'dm-is-localizable'
require 'dm-accepts_nested_attributes'

module Contriburator

  module Persistence

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
      property :homepage,   URI
      property :email,      String
      property :twitter,    String
      property :irc,        String
      property :github,     String, :unique => true
      property :location,   String

      property :created_at, ZonedTime

      has n, :contributions

      has n, :projects,
        :through => :contributions

    end

    class Project

      class Relationship

        include DataMapper::Resource

        storage_names[:default] = 'project_relationships'

        belongs_to :client,     'Contriburator::Persistence::Project', :key => true
        belongs_to :dependency, 'Contriburator::Persistence::Project', :key => true

        property :created_at,  ZonedTime

        is :localizable do
          property :description, Text
        end

      end

      class Bounty

        class Status

          include DataMapper::Resource

          storage_names[:default] = 'bounty_states'

          property :name,        String, :key      => true, :length => 20
          property :description, Text,   :required => true

        end # class Status

        include DataMapper::Resource

        storage_names[:default] = 'project_bounties'

        property :id,          Serial
        property :goal,        Integer,   :required => true
        property :start_date,  ZonedTime, :required => true
        property :stop_date,   ZonedTime, :required => true

        is :localizable do
          property :description,     Text, :required => true
        end

	      belongs_to :project
        belongs_to :status, :child_key => [ :name ]

      end # class Bounty

      include DataMapper::Resource

      storage_names[:default] = 'projects'

      property :id,            Serial

      property :github,        String, :required => true, :unique => true

      property :homepage,      URI
      property :documentation, URI
      property :issues,        URI
      property :mailing_list,  URI
      property :twitter,       String, :length => (0..255)
      property :created_at,    ZonedTime

      is :localizable do
        property :description,     Text
      end

      belongs_to :parent, self, :required => false

      has n, :forks, self, :child_key => [:parent_id]

      has n, :project_dependencies, 'Contriburator::Persistence::Project::Relationship',
        :child_key => [:client_id]

      has n, :dependencies, self,
        :through => :project_dependencies,
        :via     => :dependency

      has n, :client_projects, 'Contriburator::Persistence::Project::Relationship',
        :child_key => [:dependency_id]

      has n, :clients, self,
        :through => :client_projects,
        :via     => :client

      has n, :contributions

      has n, :members, 'Contriburator::Persistence::Contributor',
        :through => :contributions,
        :via     => :contributor

      has n, :bounties

      def name
        @name ||= github.sub('http://github.com/', '')
      end

    end

    class Contribution

      class Kind

        include DataMapper::Resource

        storage_names[:default] = 'contribution_kinds'

        property :name,        String, :key => true

        is :localizable do
          property :description, Text
        end

      end

      include DataMapper::Resource

      belongs_to :project,     :key => true
      belongs_to :contributor, :key => true
      belongs_to :kind,        :key => true, :child_key => [:kind], :parent_key => [:name]

      property :anonymous, Boolean, :default => true

    end

  end # module Persistence
end # module Contriburator

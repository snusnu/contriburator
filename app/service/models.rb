require 'dm-core'
require 'dm-migrations'
require 'dm-constraints'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-transactions'
require 'dm-types'
require 'dm-zone-types'
require 'dm-serializer'

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
      property :location,   String
      property :email,      String, :unique => true
      property :twitter,    String, :unique => true
      property :github,     String, :unique => true
      property :irc,        String

      property :created_at, DateTime

      has n, :contributions

      has n, :projects,
        :through => :contributions

    end

    class Project

      include DataMapper::Resource

      storage_names[:default] = 'projects'

      property :id,            Serial

      property :github,        String, :required => true, :unique => true

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

      has n, :project_dependencies,
        'Contriburator::Persistence::Project::Relationship',
        :child_key => [:client_id]

      has n, :dependencies, self,
        :through => :project_dependencies,
        :via     => :dependency

      has n, :client_projects,
        'Contriburator::Persistence::Project::Relationship',
        :child_key => [:dependency_id]

      has n, :clients, self,
        :through => :client_projects,
        :via     => :client

      has n, :project_contributions,
        'Contriburator::Persistence::Project::Contribution'

      has n, :contributions,
        'Contriburator::Persistence::Contribution',
        :through => :project_contributions

      has n, :members, 'Contriburator::Persistence::Contributor',
        :through => :contributions,
        :via     => :contributor

      def name
        @name ||= github.sub('http://github.com/', '')
      end

      class Relationship

        include DataMapper::Resource

        storage_names[:default] = 'project_relationships'

        belongs_to :client,
          'Contriburator::Persistence::Project',
          :key => true

        belongs_to :dependency,
          'Contriburator::Persistence::Project',
          :key => true

        property :created_at,  DateTime

        is :localizable do
          property :description, Text
        end

      end

      class Contribution

        include DataMapper::Resource

        storage_names[:default] = 'project_contributions'

        belongs_to :contribution,
          'Contriburator::Persistence::Contribution',
          :key => true

        belongs_to :project

      end

    end # Project

    class Feature

      include DataMapper::Resource

      property :id,   Serial
      property :name, String

      belongs_to :project

      has n, :feature_contributions,
        'Contriburator::Persistence::Feature::Contribution'

      has n, :contributions,
        'Contriburator::Persistence::Contribution',
        :through => :feature_contributions

      is :localizable do
        property :description, Text
      end

      class Contribution

        include DataMapper::Resource

        storage_names[:default] = 'feature_contributions'

        belongs_to :contribution,
          'Contriburator::Persistence::Contribution',
          :key => true

        belongs_to :feature

      end

    end

    class Contribution

      include DataMapper::Resource

      property :id,         Serial

      property :amount,     Integer, :min => 0
      property :anonymous,  Boolean, :default => true
      property :created_at, DateTime

      belongs_to :contributor
      belongs_to :kind, :child_key => [:kind], :parent_key => [:name]

      has 0..1, :project_contribution,
        'Contriburator::Persistence::Project::Contribution'

      has 0..1, :project,
        :through => :project_contribution

      has 0..1, :feature_contribution,
        'Contriburator::Persistence::Feature::Contribution'

      has 0..1, :feature,
        :through => :feature_contribution

      class Kind

        include DataMapper::Resource

        storage_names[:default] = 'contribution_kinds'

        property :name, String, :key => true

        is :localizable do
          property :description, Text
        end

      end

    end # Contribution

    class Bounty

      include DataMapper::Resource

      storage_names[:default] = 'project_bounties'

      property :id,          Serial
      property :goal,        Integer,   :required => true
      property :start_date,  DateTime, :required => true
      property :stop_date,   DateTime, :required => true

      is :localizable do
        property :description, Text, :required => true
      end

      belongs_to :status, :child_key => [ :name ]

      class Status

        include DataMapper::Resource

        storage_names[:default] = 'bounty_states'

        property :name,        String, :key      => true, :length => 20
        property :description, Text,   :required => true

      end # class Status

    end # class Bounty

  end # module Persistence
end # module Contriburator

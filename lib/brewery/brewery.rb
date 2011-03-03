require 'pathname'
require 'fileutils'
require 'yaml'
require 'closure-compiler'

class Brewery

  %w[ compile watch build includes templates ].each do |command|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def self.#{command}(env = nil, root = nil, file_name = nil)
        new(env, root, file_name).#{command}
      end
    RUBY
  end

  module Compilation

    def self.run(compilation, *flags)
      command = statement(compilation, *flags)
      puts "COMPILING #{command}"
      system command
      self
    end

    def self.statement(compilation, *flags)
      source, target = compilation.source, compilation.target
      "coffee -o #{target} #{flags(compilation, *flags)} --compile #{source}"
    end

    def self.flags(compilation, *flags)
      flags << '--bare' if compilation.bare?
      flags.join(' ')
    end

  end # module Compilation

  DEFAULT_ROOT        = Pathname(Dir.pwd)
  DEFAULT_ENVIRONMENT = 'development'
  DEFAULT_CONFIG_FILE = 'build.yml'

  attr_reader :env
  attr_reader :root
  attr_reader :config
  attr_reader :bundles
  attr_reader :compilations
  attr_reader :compressions
  attr_reader :includes
  attr_reader :templates

  def initialize(env = nil, root = nil, file_name = nil)
    @env          = env       || ENV['RACK_ENV'      ] || DEFAULT_ENVIRONMENT
    @root         = root      || ENV['BREWERY_ROOT'  ] || DEFAULT_ROOT
    @file_name    = file_name || ENV['BREWERY_CONFIG'] || DEFAULT_CONFIG_FILE
    @config       = Config.new(@root, @file_name)
    @root         = @config.root
    @bundles      = @config.bundles
    @compilations = @config.compilations
    @compressions = @config.compressions(@env)
    @includes     = @config.includes(@env)
    @templates    = @config.templates
  end

  def compile
    compilations.each { |bundle| Compilation.run(bundle.compilation) }
    self
  end

  def watch
    compilations.each { |bundle| Compilation.run(bundle.compilation, '--watch') }
    self
  end

  def build
    compressions.each { |bundle| Compression.run(env, bundle) }
    self
  end

  class Config

    DEFAULT_PUBLIC_DIR  = 'public'

    attr_reader :root
    attr_reader :file_name
    attr_reader :public_dir
    attr_reader :templates
    attr_reader :bundles
    attr_reader :compilations

    def initialize(root, file_name)
      @root         = root
      @file_name    = file_name
      hash          = YAML.load(File.open(@root.join(@file_name)))
      @public_dir   = @root.join(hash['public_dir'] || DEFAULT_PUBLIC_DIR)
      @bundles      = hash['bundles'  ].map { |bundle  | Bundle.new(@root, @public_dir, bundle) }
      @compilations = @bundles.select { |bundle| bundle.compilation? }
      @templates    = {}
      hash['templates'].each do |template|
        @templates.merge!(TemplateRoot.new(@root, template).templates)
      end
    end

    def includes(environment)
      bundles.map { |bundle| bundle.includes(environment) }.flatten!
    end

    def compressions(environment)
      @bundles.select { |bundle| bundle.compress?(environment) }
    end

    class TemplateRoot

      DEFAULT_EXTENSIONS = %w[ html ]

      attr_reader :source
      attr_reader :extensions
      attr_reader :pattern
      attr_reader :templates

      def initialize(root, template)
        @source     = root.join(template['source'])
        @extensions = template['extensions'] || DEFAULT_EXTENSIONS
        @pattern    = @source.join(File.join('**', "*.{#{@extensions.join(',')}}"))
        @templates  = {}
        Dir.glob(@pattern).sort.each do |path|
          relative_path = Pathname(path).relative_path_from(@source)
          template_name = relative_path.to_s.sub(relative_path.extname, '')
          @templates[template_name] = File.read(path)
        end
      end

    end # class Template

    class Bundle

      DEFAULT_ENVIRONMENTS = %w[ production ]

      attr_reader :public_dir
      attr_reader :compilation
      attr_reader :compression
      attr_reader :source
      attr_reader :target
      attr_reader :all_includes

      def initialize(root, public_dir, bundle)
        raise ArgumentError unless bundle['compile'] || bundle['compress']
        @public_dir   = public_dir
        @compilation  = Compilation.new(root, @public_dir, bundle['compile' ]) if bundle['compile' ]
        @compression  = Compression.new(root, bundle['compress']) if bundle['compress']
        @source       = @compression ? @compression.source : @compilation.target
        @target       = @compression ? @compression.target : @compilation.target
        @all_includes = bundle['includes'].to_a.map { |file| "#{@source}/#{file}" }
      end

      def compress?(environment)
        compression && compression.compress?(environment)
      end

      def includes(environment)
        compress?(environment) ? [ compression.target ] : all_includes
      end

      def compilation?
        !compilation.nil?
      end

      def compression?
        !compression.nil?
      end

      class Compilation

        attr_reader :source
        attr_reader :target

        def initialize(root, public_dir, compilation)
          @source = root.join(compilation['source'])
          @target = public_dir.join(compilation['target'])
          @bare   = compilation['bare'] || true
        end

        def bare?
          @bare
        end

      end # class Compilation

      class Compression

        attr_reader :root
        attr_reader :source
        attr_reader :includes
        attr_reader :target
        attr_reader :environments

        def initialize(root, compression)
          @root         = root
          @source       = compression['source'      ]
          @includes     = compression['include'     ] || []
          @target       = compression['target'      ] || "#{@source}-min.js"
          @environments = compression['environments'] || []
        end

        def compress?(environment)
          environments.include?(environment.to_s)
        end

      end # class Compression
    end # class Bundle
  end # class Config

  module Compression

    def self.new(env, bundle)
      klass = bundle.compilation? ? Coffeescript : Javascript
      klass.new(env, bundle)
    end

    def self.run(env, bundle)
      new(env, bundle).run
    end

    class Javascript

      attr_reader :env
      attr_reader :bundle
      attr_reader :source
      attr_reader :target
      attr_reader :combined_file

      def initialize(env, bundle)
        @env           = env
        @bundle        = bundle
        @source        = @bundle.public_dir.join(@bundle.source)
        @target        = @bundle.public_dir.join(@bundle.target)
        @combined_file = @bundle.public_dir.join("#{@source}.js")
      end

      def run
        combine
        compress
      end

      def combine
        File.open(combined_file, 'w+') do |file|
          bundle.all_includes.map { |script| bundle.public_dir.join(script)}.each do |path|
            puts "COMBINING #{path} INTO #{combined_file}"
            file.write "#{File.read(path)}\n"
          end
        end
        self
      end

      def compress
        File.open(target, 'w+') do |file|
          puts "COMPRESSING #{combined_file} INTO #{target}"
          file.write Closure::Compiler.new.compress(File.read(combined_file))
        end
        cleanup
        self
      end

      def cleanup
        puts "REMOVING temporary file: #{combined_file}"
        FileUtils.rm(combined_file)
        self
      end

    end # class Javascript

    class Coffeescript < Javascript

      def combine
        Compilation.run(bundle.compilation)
        super
        self
      end

    end # class Coffeescript
  end # class Compressor
end # class Brewery

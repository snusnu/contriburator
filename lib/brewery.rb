require 'json'
require 'fileutils'
require 'closure-compiler'

class Brewery

  DEFAULT_ENV = 'development'
  ROOT        = ENV['APP_ROOT'] || 'public'
  CONFIG      = ENV['APP_JSON'] || 'app.json'

  class << self
    %w[ build_all build_lib build_app brew watch js_includes].each do |task|
      define_method task do |env = nil, root = nil, config = nil|
        new(env, root, config).send(task)
      end
    end
  end

  attr_reader :env
  attr_reader :root
  attr_reader :js_root
  attr_reader :config
  attr_reader :app
  attr_reader :lib

  def initialize(env = nil, root = nil, config = nil)
    @env     = env  || ENV['RACK_ENV'] || DEFAULT_ENV
    @root    = root || Pathname(Dir.pwd).join(ROOT)
    @js_root = @root.join('js')
    @config  = JSON.parse(File.read(@root.join(config || CONFIG)))
    @app     = ENV['APP_JS'] || @root.join('js/app.js')
    @lib     = ENV['LIB_JS'] || @root.join('js/lib.js')
  end

  def js_includes
    if production?
      %w[ js/lib-min.js js/app-min.js ]
    else
      config['lib'].map { |lib| "js/lib/#{lib}.js" } +
      config['app'].map { |app| "js/app/#{app}.js" }
    end
  end

  def build_all(lib_target = lib, app_target = app)
    build_lib(lib_target)
    build_app(app_target)
    self
  end

  def build_lib(target = lib)
    puts "[Brewery] - Building lib ..."
    build(target) { combine_lib(target) }
    self
  end

  def build_app(target = app)
    puts "[Brewery] - Building app ..."
    build(target) { combine_app(target) }
    self
  end

  def brew
    puts "[Brewery] - Compiling coffeescripts ..."
    `coffee -o #{target_folder} --compile #{source_folder}`
    self
  end

  def watch
    puts "[Brewery] - Compiling coffeescripts ..."
    `coffee -o #{target_folder} --watch --compile #{source_folder}`
    self
  end

  def build(target)
    yield if block_given?
    if production?
      minify(target)
      cleanup(target)
    end
    self
  end

  def combine_app(target = app)
    scripts = config['app']
    if scripts.empty?
      puts "No (.coffee) scripts listed in public/app.json['app']"
    else
      coffee_scripts = scripts.map { |script| "#{root}/app/#{script}.coffee" }
      coffee_inputs  = coffee_scripts.join(' ')

      def log_compiled_scripts(scripts)
        scripts.each do |script|
          js = script.sub('public/app', 'public/js/app').sub('.coffee', '.js')
          puts "[Brewery] - COMPILED: #{script} INTO #{js}"
        end
      end

      if production?
        `coffee -o #{js_root} --bare --join --compile #{coffee_inputs}`
        `mv #{js_root.join('concatenation.js')} #{target}`
        log_compiled_scripts(coffee_scripts)
        puts "[Brewery] - COMBINED: #{js_root.join('app/*.js')} INTO #{target}"
      else
        `coffee -o #{js_root.join('app')} --bare --compile #{coffee_inputs}`
        log_compiled_scripts(coffee_scripts)
      end

    end
    self
  end

  def combine_lib(target = lib)
    scripts = config['lib']
    if scripts.empty?
      puts "No (.js) scripts listed in public/app.json['lib']"
    else
      if production?
        File.open(target, 'w+') do |file|
          scripts.map { |script| "#{js_root}/lib/#{script}.js" }.each do |script|
            file.write "#{File.read(script)}\n"
          end
        end
        puts "[Brewery] - COMBINED: #{js_root.join('lib/*.js')} INTO #{target}"
      else
        puts "[Brewery] - SKIPPED: combining lib in development mode"
      end
    end
    self
  end

  def minify(script)
    output = minified_name(script)
    target = js_root.join(output)
    File.open(target, 'w+') do |file|
      file.write Closure::Compiler.new.compress(File.read(script))
    end
    puts "[Brewery] - MINIFIED: #{script} INTO #{target}"
    self
  end

  def cleanup(target)
    FileUtils.rm(target)
    puts "[Brewery] - DELETED:  #{target}"
    self
  end

  def minified_name(script)
    name, extension = script.to_s.split('/').last.split('.')
    "#{name}-min.#{extension}"
  end

  def production?
    env == 'production'
  end

  def source_folder
    root.join('app')
  end

  def target_folder
    js_root.join('app')
  end

end

require 'brewery'

namespace :build do

  desc "Compile coffeescript files to javascript files"
  task :compile do
    Brewery.compile
  end

  desc "Compile coffeescript files to javascript files continuously"
  task :watch do
    Brewery.watch
  end

end

desc "Compile coffeescripts (also combine and minify in production)"
task :build do
	Brewery.build
end

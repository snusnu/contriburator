require 'pathname'

require 'json'
require 'sinatra/base'
require 'mustache/sinatra'

require 'config'
require 'models'
require 'views'

module Contriburator

  class Server < Sinatra::Base

    enable :sessions

    register Mustache::Sinatra

    set :mustache, {
      :namespace => Contriburator::Views
    }

    get '/' do
      Views::Home.new.render
    end

  end # class Server
end # module Contriburator

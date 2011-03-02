require 'pathname'

require 'json'
require 'sinatra/base'
require 'omniauth'

require 'config'
require 'models'

require 'erubis'
require 'brewery'

# make erb use erubis by default
Tilt.register :erb, Tilt[:erubis]

module Contriburator

  class Server < Sinatra::Base

    enable :sessions

    set :public, Config.public_dir

    use OmniAuth::Builder do
      provider :github, Config['github']['id'], Config['github']['secret']
    end

    helpers do

      def authenticate_params(credentials)
        authenticate(credentials[:login], credentials[:token])
      end

      def authenticate_session(login)
        authenticate(login, session[:token])
      end

      def authenticate(login, token)
        user = Persistence::User.first(:login => login)
        halt 403 unless user && authorized?(user, token)
        user
      end

      def authorized?(user, token)
        user.token == token
      end

    end

    not_found do
      File.read(Config.public_dir.join('404.html'))
    end

    get '/' do
      erb File.read(Config.public_dir.join('app.html')), :locals => {
        :js_includes => Brewery.js_includes
      }
    end

    get '/auth/github/callback' do
      login = request.env['omniauth.auth']['user_info']['nickname']
      user = Persistence::Contributor.first_or_create(:login => login)

      session[:token] = user.token

      { :login => login }.to_json
    end

  end # class Server
end # module Contriburator

require 'pathname'

require 'json'
require 'sinatra/base'
require 'mustache/sinatra'
require 'omniauth'

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

      def requested_status
        (params[:status] || '').split(',')
      end

    end

    get '/' do
      Views::Home.new.render
    end

    get '/auth/github/callback' do
      login = request.env['omniauth.auth']['user_info']['nickname']
      user = Persistence::Contributor.first_or_create(:login => login)

      session[:token] = user.token

      redirect "/users/#{user.login}/edit"
    end

    get '/users/:login/edit' do
      user = authenticate_session(params[:login])
      Views::Users::Edit.new(user).render
    end

    get '/users/:login' do
      Views::Users::Show.new(params[:login]).render
    end


  end # class Server
end # module Contriburator

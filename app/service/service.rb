require 'pathname'
require 'digest/md5'

require 'json'
require 'sinatra/base'
require 'omniauth'

require 'service/config'
require 'service/models'

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

      def current_user
        id = session[:user] && session[:user][:id]
        return unless id
        Persistence::Contributor.get(id)
      end

      def authenticate(login, token)
        halt 403 unless authorized?(token)
        Persistence::Contributor.first(:login => login)
      end

      def authorized?(token)
        session[:token] == token
      end

      def profile_image_hash(email)
        email ? Digest::MD5.hexdigest(email) : '00000000000000000000000000000000'
      end

    end

    not_found do
      # TODO handle this differently
      File.read(Config.public_dir.join('404.html'))
    end

    get '/' do
      erb File.read(Config.root.join('app/app.html'))
    end

    get '/auth/github/callback' do
      auth = request.env['omniauth.auth']
      nick = auth && auth['user_info']['nickname']
      return 500 unless nick

      user = Persistence::Contributor.first_or_create(
        {
          :github   => nick
        },
        {
          :email    => auth['user_info']['email'],
          :name     => auth['user_info']['name' ],
          :company  => auth['extra']['user_hash']['company' ],
          :location => auth['extra']['user_hash']['location'],
          :homepage => auth['extra']['user_hash']['blog'    ]
        }
      )

      session[:user] = {
        :id    => user.id,
        :token => auth['credentials']['token']
      }

      redirect '/'
    end

    get '/signout' do
      session[:user] = nil
      redirect '/'
    end

  end # class Server
end # module Contriburator

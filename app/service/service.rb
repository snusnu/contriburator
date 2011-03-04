require 'pathname'

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

      def authenticate(login, token)
        halt 403 unless authorized?(token)
        Persistence::User.first(:login => login)
      end

      def authorized?(token)
        session[:token] == token
      end

    end

    not_found do
      # TODO handle this differently
      File.read(Config.public_dir.join('404.html'))
    end

    get '/' do
      erb File.read(Config.public_dir.join('app.html'))
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
          :email    => info['user_info']['email'],
          :name     => info['user_info']['name' ],
          :company  => info['extra']['user_hash']['company' ],
          :location => info['extra']['user_hash']['location'],
          :homepage => info['extra']['user_hash']['blog'    ]
        }
      )

      session[:token] = info['credentials']['token']

      {
        :user => user.attributes,
        :token => session[:token]
      }.to_json
    end

  end # class Server
end # module Contriburator

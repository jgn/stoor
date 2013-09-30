module Stoor
  class GithubAuth < Sinatra::Base

    set :github_options, {
      :scopes    => "user,user:email",
      :client_id => ENV['STOOR_GITHUB_CLIENT_ID'],
      :secret    => ENV['STOOR_GITHUB_CLIENT_SECRET']
    }

    register Sinatra::Auth::Github
    register Mustache::Sinatra

    get '/logout' do
      logout!
      mustache :logout
    end

    get '/*' do
      session['stoor.github.authorized'] = nil

      pass unless ENV['STOOR_GITHUB_CLIENT_ID'] && ENV['STOOR_GITHUB_CLIENT_SECRET']

      pass if request.path_info =~ /\./

      authenticate!
      if ENV['STOOR_GITHUB_TEAM_ID']
        github_team_authenticate!(ENV['STOOR_GITHUB_TEAM_ID'])
      end

      session['stoor.github.authorized'] = 'yes'

      email = nil
      emails = github_user.api.emails
      if ENV['STOOR_GITHUB_EMAIL_DOMAIN']
        email = emails.find { |e| e =~ /#{ENV['STOOR_GITHUB_EMAIL_DOMAIN']}/ }
      end
      email ||= emails.first
      session['gollum.author'] = { :name => github_user.name, :email => email }
      pass
    end
  end
end

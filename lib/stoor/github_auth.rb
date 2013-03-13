module Stoor
  class GithubAuth < Sinatra::Base

    set :github_options, {
      :scopes    => "user,user:email",
      :client_id => ENV['GITHUB_CLIENT_ID'],
      :secret    => ENV['GITHUB_CLIENT_SECRET']
    }

    register Sinatra::Auth::Github
    register Mustache::Sinatra

    get '/logout' do
      logout!
      mustache :logout
    end

    get '/*' do
      ENV['GITHUB_AUTHORIZED'] = nil

      pass unless ENV['GITHUB_CLIENT_ID'] && ENV['GITHUB_CLIENT_SECRET']

      pass if request.path_info =~ /\./

      authenticate!
      if ENV['GITHUB_TEAM_ID']
        github_team_authenticate!(ENV['GITHUB_TEAM_ID'])
      end

      ENV['GITHUB_AUTHORIZED'] = "yes"

      email = nil
      emails = github_user.api.emails
      if ENV['GITHUB_EMAIL_DOMAIN']
        email = emails.find { |e| e =~ /#{ENV['GITHUB_EMAIL_DOMAIN']}/ }
      end
      email ||= emails.first
      session['gollum.author'] = { :name => github_user.name, :email => email }
      pass
    end
  end
end

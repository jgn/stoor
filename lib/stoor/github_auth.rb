module Stoor
  class GithubAuth < Sinatra::Base

    register Sinatra::Auth::Github
    register Mustache::Sinatra

    get '/logout' do
      logout!
      mustache :logout
    end

    get '/sorry' do
      mustache :sorry
    end

    get '/unauthorized' do
      mustache :unauthorized
    end

    get '/*' do
      session['stoor.github.authorized'] = nil

      pass unless github_options[:client_id] && github_options[:secret]

      pass if request.path_info =~ /\./

      authenticate!
      if stoor_options[:github_team_id]
        github_team_authenticate!(stoor_options[:github_team_id])
      end

      session['stoor.github.authorized'] = 'yes'

      email = nil
      emails = github_user.api.emails
      if stoor_options[:github_email_domain]
        email = emails.find { |e| e =~ /#{stoor_options[:github_email_domain]}/ }
        if stoor_options[:github_email_domain_required] && email.nil?
          redirect to('/unauthorized')
        end
      end
      email ||= emails.first
      session['gollum.author'] = { :name => github_user.name, :email => email }
      pass
    end

    private

    def github_options
      @github_options ||= settings.github_options || {}
    end

    def stoor_options
      @stoor_options ||= settings.stoor_options || {}
    end
  end
end

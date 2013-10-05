require 'spec_helper'

module Stoor

  # Follows https://github.com/atmos/sinatra_auth_github/blob/master/spec/login_spec.rb
  # To run these specs, define a testing app at https://github.com/settings/applications/new,
  # with a callback URL such as http://localhost:9393/auth/github/callback
  # Then
  #   STOOR_GITHUB_CLIENT_ID=xxx STOOR_GITHUB_CLIENT_SECRET=yyy stoor -p 9393
  # Authenticate.
  # Now you can test:
  #   STOOR_GITHUB_CLIENT_ID=xxx STOOR_GITHUB_CLIENT_SECRET=yyy STOOR_TESTING_USER=jgn bundle exec rspec

  describe "Logged in users" do
    include Stoor::Test::Helper

    let(:inner_app) { ->(env) { [200, { }, [ 'protected info' ]] } }
    let(:sessions) { Rack::Session::Cookie.new(inner_app, secret: 'boo') }
    let(:app) { GithubAuth.new(sessions) }

    include_context 'repo'
    ENV['STOOR_WIKI_PATH'] = './repo'

    before do
      Stoor::GithubAuth.set :github_options, {
        scopes: 'user:email',
        client_id: ENV['STOOR_GITHUB_CLIENT_ID'],
        secret: ENV['STOOR_GITHUB_CLIENT_SECRET']
      }
      Stoor::GithubAuth.set :stoor_options, {
        github_team_id: ENV['STOOR_GITHUB_TEAM_ID'],
        github_email_domain: ENV['STOOR_GITHUB_EMAIL_DOMAIN']
      }
      Stoor::GithubAuth.send(:enable, :sessions)
      @user = make_user(ENV['STOOR_TESTING_USER'], [ 'effie@example.com', 'effie@7fff.com', 'john@7fff.com' ])
      login_as @user
    end

    it 'Shows the home page' do
      get '/'
      expect(last_response.body).to match('protected info')
    end

    it 'Sets the gollum.user with the first email' do
      get '/'
      expect(last_request.env['rack.session']['gollum.author']).to eq(name: 'Effie Klinker', email: 'effie@example.com')
    end

    it 'Sets the gollum.user according to domain if specified' do
      Stoor::GithubAuth.set :stoor_options, {
        github_team_id: ENV['STOOR_GITHUB_TEAM_ID'],
        github_email_domain: '7fff.com'
      }
      get '/'
      expect(last_request.env['rack.session']['gollum.author']).to eq(name: 'Effie Klinker', email: 'effie@7fff.com')
    end

    it 'logs the user out' do
      get '/'
      get '/logout'
      expect(last_response.status).to eql(200)
      expect(last_response.body).to match("You're logged out")

      get '/'
      expect(last_response.status).to eql(302)
      expect(last_response.headers['Location']).to match(/^https:\/\/github\.com\/login\/oauth\/authorize/)
    end

    it 'shows the securocat when github returns an oauth error' do
      get '/auth/github/callback?error=redirect_uri_mismatch'
      follow_redirect!
      expect(last_response.body).to match(/securocat\.png/)
    end
  end
end

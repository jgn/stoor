#!/usr/bin/env ruby

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'rubygems'
require 'bundler/setup'
require 'sinatra_auth_github'
require 'gollum/app'
require 'stoor'
require 'rack/null_logger'

ENV['RACK_ENV'] ||= 'development'

config = Stoor::Config.new(__FILE__, ENV['STOOR_RUNNING_VIA_CMD'])

domain       = config.env('DOMAIN') || 'localhost'
secret       = config.env('SECRET') || 'stoor'
expire_after = (config.env('EXPIRE_AFTER') || '3600').to_i

gollum_path = config.env('WIKI_PATH') || config.dirname

config.dump_env
config.log "gollum_path: #{gollum_path}"

if message = config.repo_missing?(gollum_path)
  puts message
  run Proc.new { |env| [ 200, { 'Content-Type' => 'text/plain' }, [ message ] ] }
else
  use Rack::Session::Cookie, :domain => domain, :key => 'rack.session', :secret => secret, :expire_after => expire_after
  use Rack::CommonLogger, config.access_logger
  use Stoor::Logger, config.log_stream, Logger::INFO

  scopes = [ 'user:email' ]
  scopes << 'user' if config.env('GITHUB_TEAM_ID')
  Stoor::GithubAuth.set :github_options, {
    scopes:    scopes.join(','),
    client_id: config.env('GITHUB_CLIENT_ID'),
    secret:    config.env('GITHUB_CLIENT_SECRET')
  }
  Stoor::GithubAuth.set :stoor_options, {
    github_team_id:               config.env('GITHUB_TEAM_ID'),
    github_email_domain:          config.env('GITHUB_EMAIL_DOMAIN'),
    github_email_domain_required: config.env('GITHUB_EMAIL_DOMAIN_REQUIRED')
  }
  use Stoor::GithubAuth

  use Stoor::GitConfig, gollum_path
  use Stoor::TransformContent,
    pass_condition: ->(request) { request.session['gollum.author'].nil? },
    regexp: /(<div id="footer">)(.*?)(<\/div>)/im,
    before: ->(request) do
      <<-HTML
        <div style="float: left;">
      HTML
    end,
    after: ->(request) do
      <<-HTML
        </div>
        <div style="float: right;">
          <p style="text-align: right; font-size: .9em; line-height: 1.6em; color: #999; margin: 0.9em 0;">
            Commiting as <b>#{request.session['gollum.author'][:name]}</b> (#{request.session['gollum.author'][:email]})#{" | <a href='/logout'>Logout</a>" if request.session['stoor.github.authorized']}
          </p>
        </div>
      HTML
    end
  if config.env('WIDE')
    use Stoor::TransformContent,
      regexp: /<body>/,
      after: '<style type="text/css">#wiki-wrapper { width: 90%; } .markdown-body table { width: 100%; }</style>'
  end
  if config.env('READONLY')
    use Stoor::ReadOnly, '/sorry'
    use Stoor::TransformContent,
      regexp: /<body>/,
      after: <<-STYLE
        <style type="text/css">
          #minibutton-new-page    { display: none; }
          #minibutton-rename-page { display: none; }
          a.action-edit-page      { display: none; }
          #delete-link            { display: none; }
        </style>
      STYLE
  end

  Precious::App.set(:gollum_path, gollum_path)
  Precious::App.set(:default_markup, :markdown)
  Precious::App.set(:wiki_options, { :universal_toc =>false })
  run Precious::App
end

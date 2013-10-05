#!/usr/bin/env ruby

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'rubygems'
require 'logger'
require 'bundler/setup'
require 'sinatra_auth_github'
require 'gollum/app'
require 'stoor'

# Force the NullLogger to be a no-op, since it keeps getting bound into the
# Request instance.
module Rack
  class NullLogger
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    end
  end
end

ENV['RACK_ENV'] ||= 'development'

domain       = ENV['STOOR_DOMAIN'] || 'localhost'
secret       = ENV['STOOR_SECRET'] || 'stoor'
expire_after = (ENV['STOOR_EXPIRE_AFTER'] || '3600').to_i

log_frag = "#{File.dirname(__FILE__)}/log/#{ENV['RACK_ENV']}"
access_logger = Logger.new("#{log_frag}_access.log")
access_logger.instance_eval do
  def write(msg); self.send(:<<, msg); end
end
access_logger.level = Logger::INFO
log_stream = File.open("#{log_frag}.log", 'a+')
log_stream.sync = true

gollum_path = ENV['STOOR_WIKI_PATH'] || File.expand_path(File.dirname(__FILE__))
repo_exists = true
begin
  Gollum::Wiki.new(gollum_path)
rescue Gollum::InvalidGitRepositoryError
  repo_exists = false
  message = "Sorry, #{gollum_path} is not a git repository; you might try `cd #{gollum_path}; git init .`."
rescue NameError
  repo_exists = false
  message = "Sorry, #{gollum_path} doesn't exist; set the environment variable STOOR_WIKI_PATH to point to a git repository."
end

use Rack::Session::Cookie, :domain => domain, :key => 'rack.session', :secret => secret, :expire_after => expire_after
use Rack::CommonLogger, access_logger
use Stoor::Logger, log_stream, Logger::INFO
if repo_exists
  Stoor::GithubAuth.set :github_options, {
    scopes:    'user:email',
    client_id: ENV['STOOR_GITHUB_CLIENT_ID'],
    secret:    ENV['STOOR_GITHUB_CLIENT_SECRET']
  }
  Stoor::GithubAuth.set :stoor_options, {
    github_team_id:      ENV['STOOR_GITHUB_TEAM_ID'],
    github_email_domain: ENV['STOOR_GITHUB_EMAIL_DOMAIN']
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
  if ENV['STOOR_WIDE']
    use Stoor::TransformContent,
      regexp: /<body>/,
      after: '<style type="text/css">#wiki-wrapper { width: 90%; } .markdown-body table { width: 100%; }</style>'
  end

  Precious::App.set(:gollum_path, gollum_path)
  Precious::App.set(:default_markup, :markdown)
  Precious::App.set(:wiki_options, { :universal_toc =>false })
  run Precious::App
else
  run Proc.new { |env| [ 200, { 'Content-Type' => 'text/plain' }, [ message ] ] }
  puts message
end

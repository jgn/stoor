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
log_frag = "#{File.dirname(__FILE__)}/log/#{ENV['RACK_ENV']}"
access_logger = Logger.new("#{log_frag}_access.log")
access_logger.instance_eval do
  def write(msg); self.send(:<<, msg); end
end
access_logger.level = Logger::INFO
log_stream = File.open("#{log_frag}.log", 'a+')
log_stream.sync = true

domain = ENV['STOOR_DOMAIN'] || 'localhost'
secret = ENV['STOOR_SECRET'] || 'stoor'
expire_after = (ENV['STOOR_EXPIRE_AFTER'] || '3600').to_i

wiki_path = ENV['WIKI_PATH_IN_USE'] = ENV['WIKI_PATH'] || File.expand_path(File.dirname(__FILE__))

use Rack::CommonLogger, access_logger
use Stoor::Logger, log_stream, Logger::INFO
use Rack::Session::Cookie, :domain => domain, :key => 'rack.session', :secret => secret, :expire_after => expire_after

use Stoor::GithubAuth
use Stoor::GitConfig
use Stoor::Decorate
if ENV['STOOR_WIDE']
  use Stoor::AddAfter, /<body>/, '<style type="text/css">#wiki-wrapper { width: 90%; } .markdown-body table { width: 100%; }</style>'
end

Precious::App.set(:gollum_path, wiki_path)
Precious::App.set(:default_markup, :markdown)
Precious::App.set(:wiki_options, { :universal_toc =>false })
run Precious::App

#!/usr/bin/env ruby

ENV['RACK_ENV'] ||= 'development'

unless ENV['RACK_ENV'] == 'development'
  log = File.new("log/#{ENV['RACK_ENV']}.log", "a+")
  $stdout.reopen(log)
end

domain = ENV['STOOR_DOMAIN'] || 'localhost'
secret = ENV['STOOR_SECRET'] || 'stoor'
expire_after = (ENV['STOOR_EXPIRE_AFTER'] || '3600').to_i

wiki_path = ENV['WIKI_PATH_IN_USE'] = ENV['WIKI_PATH'] || File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'bundler/setup'
require 'sinatra_auth_github'
require 'gollum/frontend/app'

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'stoor'

Precious::App.set(:gollum_path, wiki_path)
Precious::App.set(:default_markup, :markdown)
Precious::App.set(:wiki_options, { :universal_toc =>false })

use Rack::Session::Cookie, :domain => domain, :key => 'rack.session', :secret => secret, :expire_after => expire_after
use Stoor::GithubAuth
use Stoor::GitConfig
use Stoor::Decorate
run Precious::App

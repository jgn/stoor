#!/usr/bin/env ruby

ENV['RACK_ENV'] ||= 'development'

unless ENV['RACK_ENV'] == 'development'
  log = File.new("log/#{ENV['RACK_ENV']}.log", "a+")
  $stdout.reopen(log)
end

domain = ENV['TRAHALD_DOMAIN'] || 'localhost'
secret = ENV['TRAHALD_SECRET'] || 'trahald'
expire_after = (ENV['TRAHALD_EXPIRE_AFTER'] || '3600').to_i

wiki_path = ENV['WIKI_PATH_IN_USE'] = ENV['WIKI_PATH'] || File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'bundler/setup'
require 'sinatra_auth_github'
require 'gollum/frontend/app'

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'trahald'

Precious::App.set(:gollum_path, wiki_path)
Precious::App.set(:default_markup, :markdown)
Precious::App.set(:wiki_options, { :universal_toc =>false })

use Rack::Session::Cookie, :domain => domain, :key => 'rack.session', :secret => secret, :expire_after => expire_after
use Trahald::GithubAuth
use Trahald::GitConfig
use Trahald::Decorate
run Precious::App

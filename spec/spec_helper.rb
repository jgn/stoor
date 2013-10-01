require 'rack/test'
require 'ostruct'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

class String
  def strip_heredoc
    indent = scan(/^[ \t]*(?=\S)/).min.size || 0
    gsub(/^[ \t]{#{indent}}/, '')
  end
end

require 'warden/github'
require 'warden/test/helpers'
require 'warden/github/user'

# Follows https://github.com/atmos/sinatra_auth_github/blob/master/lib/sinatra/auth/github/test/test_helper.rb
module Stoor
  module Test
    module Helper
      include Warden::Test::Helpers

      class User < Warden::GitHub::User
        attr_accessor :api
      end

      def make_user(login, emails = 'effie@example.com', override_attributes = {})
        emails = Array(emails)
        attributes = {
            'login'   => login,
            'email'   => emails.first,
            'name'    => "Effie Klinker",
            'company' => "7fff",
            'gravatar_id' => 'a'*32,
            'avatar_url'  => 'https://a249.e.akamai.net/assets.github.com/images/gravatars/gravatar-140.png?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png',
        }
        User.new(attributes.merge! override_attributes).tap do |user|
          user.api = OpenStruct.new(:emails => emails)
        end
      end

   end
  end
end

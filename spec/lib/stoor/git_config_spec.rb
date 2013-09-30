require 'stoor/git_config'
require 'spec_helper'
require 'grit'

module Stoor
  describe GitConfig do
    let(:inner_app) { ->(env) { [200, { }, []] } }
    let(:app) { GitConfig.new(inner_app, 'repo') }

    before do
      repo = Grit::Repo.init('repo')
      File.open('repo/.git/config', 'a+') do |f|
        f.write <<-GITCONFIG.strip_heredoc
        [user]
          name = Mortimer Snerd
          email = snerd@example.com
        GITCONFIG
      end
    end

    after do
      FileUtils.rm_rf 'repo'
    end

    it 'finds git config user.name and user.email and puts them into the session under the key gollum.author' do
      get '/'
      expect(last_request.env['rack.session']['gollum.author']).to eq(name: 'Mortimer Snerd', email: 'snerd@example.com')
    end
  end
end

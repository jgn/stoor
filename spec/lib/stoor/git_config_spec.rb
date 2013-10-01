require 'spec_helper'

module Stoor
  describe GitConfig do
    let(:inner_app) { ->(env) { [200, { }, []] } }
    let(:app) { GitConfig.new(inner_app, 'repo') }

    include_context 'repo'

    it 'finds git config user.name and user.email and puts them into the session under the key gollum.author' do
      get '/'
      expect(last_request.env['rack.session']['gollum.author']).to eq(name: 'Mortimer Snerd', email: 'snerd@example.com')
    end
  end
end

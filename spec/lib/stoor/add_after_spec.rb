require 'stoor/add_after'
require 'spec_helper'

module Stoor

  describe AddAfter, 'content-type matching' do

    context 'default with text/plain response' do
      let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/plain' }, '<body>'] } }
      let(:app) { AddAfter.new(inner_app, /<body>/, 'stuff') }

      it "skips" do
        get '/'
        expect(last_response.body).to eq('<body>')
      end
    end

    context 'default with text/html response' do
      let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<body>'] } }
      let(:app) { AddAfter.new(inner_app, /<body>/, 'stuff') }

      it "processes" do
        get '/'
        expect(last_response.body).to eq('<body>stuff')
      end
    end

    context 'specifying text/plain with text/html response' do
      let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<body>'] } }
      let(:app) { AddAfter.new(inner_app, /<body>/, 'stuff', 'text/plain') }

      it "skips" do
        get '/'
        expect(last_response.body).to eq('<body>')
      end
    end

    context 'specifying regexp with text/html response' do
      let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/whatever' }, '<body>'] } }
      let(:app) { AddAfter.new(inner_app, /<body>/, 'stuff', /\Atext\//) }

      it "processes" do
        get '/'
        expect(last_response.body).to eq('<body>stuff')
      end
    end

  end

  describe AddAfter, 'insertion' do
    let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<body>'] } }
    let(:app) { AddAfter.new(inner_app, /<body>/, 'stuff') }

    it 'adds text after the first occurrence of a search string' do
      get '/'
      expect(last_response.body).to eq('<body>stuff')
    end
  end

  describe AddAfter, 'insertion with two potential matches' do
    let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<body> <body>'] } }
    let(:app) { AddAfter.new(inner_app, /<body>/, 'stuff') }

    it 'adds text only after the first occurrence of a search string' do
      get '/'
      expect(last_response.body).to eq('<body>stuff <body>')
    end
  end

  describe AddAfter, 'insertion if response is an Array' do
    let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, [ '<bo', 'dy>' ] ] } }
    let(:app) { AddAfter.new(inner_app, /<body>/, 'stuff') }

    it 'adds text after the first occurrence of a search string' do
      get '/'
      expect(last_response.body).to eq('<body>stuff')
    end
  end

  describe AddAfter, 'status code implies no body' do
    let(:inner_app) { ->(env) { [204, { 'Content-Type' => 'text/html' }, '<body>' ] } }
    let(:app) { AddAfter.new(inner_app, /<body>/, 'stuff') }

    it 'skips' do
      get '/'
      expect(last_response.body).to eq('<body>')
    end
  end

  describe AddAfter, 'response is transfer-encoded' do
    let(:inner_app) { ->(env) { [200, { 'Transfer-Encoding' => 'Chunked', 'Content-Type' => 'text/html' }, '<body>' ] } }
    let(:app) { AddAfter.new(inner_app, /<body>/, 'stuff') }

    it 'skips' do
      get '/'
      expect(last_response.body).to eq('<body>')
    end
  end
end

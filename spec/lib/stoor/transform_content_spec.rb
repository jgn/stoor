require 'stoor/transform_content'
require 'spec_helper'

module Stoor

  describe TransformContent, 'content-type matching' do
    context 'default with text/plain response' do
      let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/plain' }, '<body>'] } }
      let(:app) { TransformContent.new(inner_app, regexp: /<body>/, after: 'after-text') }

      it "skips" do
        get '/'
        expect(last_response.body).to eq('<body>')
      end
    end

    context 'default with text/html response' do
      let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<body>'] } }
      let(:app) { TransformContent.new(inner_app, regexp: /<body>/, after: 'after-text') }

      it "processes" do
        get '/'
        expect(last_response.body).to eq('<body>after-text')
      end
    end

    context 'specifying text/plain with text/html response' do
      let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<body>'] } }
      let(:app) { TransformContent.new(inner_app, regexp: /<body>/, after: 'after-text', content_type: 'text/plain') }

      it "skips" do
        get '/'
        expect(last_response.body).to eq('<body>')
      end
    end

    context 'specifying regexp with text/html response' do
      let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/whatever' }, '<body>'] } }
      let(:app) { TransformContent.new(inner_app, regexp: /<body>/, after: 'after-text', content_type: /\Atext\//) }

      it "processes" do
        get '/'
        expect(last_response.body).to eq('<body>after-text')
      end
    end
  end

  describe TransformContent, 'passes on condition' do
    let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<body>'] } }
    let(:app) { TransformContent.new(inner_app, regexp: /<body>/, after: 'after-text', pass_condition: ->(env) { true }) }

    it 'skips when a passed-in condition returns true' do
      get '/'
      expect(last_response.body).to eq('<body>')
    end
  end

  describe TransformContent, 'insertion after' do
    let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<body>'] } }
    let(:app) { TransformContent.new(inner_app, regexp: /<body>/, after: 'after-text') }

    it 'adds text after the first occurrence of a search string' do
      get '/'
      expect(last_response.body).to eq('<body>after-text')
    end
  end

  describe TransformContent, 'insertion before' do
    let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<body>'] } }
    let(:app) { TransformContent.new(inner_app, regexp: /<body>/, before: 'before-text') }

    it 'adds text before the first occurrence of a search string' do
      get '/'
      expect(last_response.body).to eq('before-text<body>')
    end
  end

  describe TransformContent, 'insertion before and after' do
    let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<body>'] } }
    let(:app) { TransformContent.new(inner_app, regexp: /<body>/, before: 'before-text', after: 'after-text') }

    it 'adds text before and after the first occurrence of a search string' do
      get '/'
      expect(last_response.body).to eq('before-text<body>after-text')
    end
  end

  describe TransformContent, 'insertion before and after with captures' do
    let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<div>foo</div>'] } }
    let(:app) { TransformContent.new(inner_app, regexp: /(<div>)(.*?)(<\/div>)/, before: 'before-text', after: 'after-text') }

    it 'adds text before and after the middle capture' do
      get '/'
      expect(last_response.body).to eq('<div>before-textfooafter-text</div>')
    end
  end

  describe TransformContent, 'not 0 or 3 captures' do
    let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<div>foo</div>'] } }
    let(:app) { TransformContent.new(inner_app, regexp: /(<div>).*?(<\/div>)/, before: 'before-text', after: 'after-text') }

    it 'raises an exception' do
      expect { get '/' }.to raise_error
    end
  end

  describe TransformContent, 'insertion after with two potential matches' do
    let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, '<body> <body>'] } }
    let(:app) { TransformContent.new(inner_app, regexp: /<body>/, after: 'after-text') }

    it 'adds text only after the first occurrence of a search string' do
      get '/'
      expect(last_response.body).to eq('<body>after-text <body>')
    end
  end

  describe TransformContent, 'insertion if response is an Array' do
    let(:inner_app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, [ '<bo', 'dy>' ] ] } }
    let(:app) { TransformContent.new(inner_app, regexp: /<body>/, after: 'after-text') }

    it 'adds text after the first occurrence of a search string' do
      get '/'
      expect(last_response.body).to eq('<body>after-text')
    end
  end

  describe TransformContent, 'status code implies no body' do
    let(:inner_app) { ->(env) { [204, { 'Content-Type' => 'text/html' }, '<body>' ] } }
    let(:app) { TransformContent.new(inner_app, regexp: /<body>/, after: 'after-text') }

    it 'skips' do
      get '/'
      expect(last_response.body).to eq('<body>')
    end
  end

  describe TransformContent, 'response is transfer-encoded' do
    let(:inner_app) { ->(env) { [200, { 'Transfer-Encoding' => 'Chunked', 'Content-Type' => 'text/html' }, '<body>' ] } }
    let(:app) { TransformContent.new(inner_app, regexp: /<body>/, after: 'after-text') }

    it 'skips' do
      get '/'
      expect(last_response.body).to eq('<body>')
    end
  end
end

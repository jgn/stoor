require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

class String
  def strip_heredoc
    indent = scan(/^[ \t]*(?=\S)/).min.size || 0
    gsub(/^[ \t]{#{indent}}/, '')
  end
end

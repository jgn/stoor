require 'rack'

module Stoor
  class AddAfter
    include Rack::Utils

    attr_reader :status, :headers
    attr_reader :rxp, :string, :content_type

    def initialize(app, rxp, string, content_type = 'text/html')
      @app, @rxp, @string, @content_type = app, rxp, string, content_type
    end

    def call(env)
      @status, @headers, response = @app.call(env)
      @headers = HeaderHash.new(@headers)

      if has_body && not_encoded && headers['content-type'] &&
        headers['content-type'].index(content_type)

        content = Array(response).join('')

        if content =~ rxp
          pre, match, post = $`, $&, $'
          new_body = pre + match + string + post
          headers['Content-Length'] = new_body.bytesize.to_s
          return [status, headers, [new_body]]
        end
      end

      [status, headers, response]
    end

    private

    def has_body
      !STATUS_WITH_NO_ENTITY_BODY.include?(status)
    end

    def not_encoded
      !headers['transfer-encoding']
    end
  end
end

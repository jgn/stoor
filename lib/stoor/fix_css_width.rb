module Stoor
  class FixCssWidth
    include Rack::Utils

    def initialize(app); @app = app; end

    def call(env)
      @request = Rack::Request.new(env)

      status, headers, response = @app.call(env)
      headers = HeaderHash.new(headers)

      if !STATUS_WITH_NO_ENTITY_BODY.include?(status) &&
          !headers['transfer-encoding'] &&
          headers['content-type'] &&
          headers['content-type'].include?("text/html")

        # TODO: If the response isn't an Array, it's a Rack::File or something, so ignore
        if response.respond_to? :inject
          content = response.inject("") { |content, part| content << part }
          if content =~ /<body>/
            pre, match, post = $`, $&, $'
            new_body = pre + match + '<style type="text/css">#wiki-wrapper { width: 90%; }</style>' + post
            headers['Content-Length'] = new_body.bytesize.to_s
            return [status, headers, [new_body]]
          end
        end
      end

      [status, headers, response]
    end
  end
end

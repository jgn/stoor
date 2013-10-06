require 'rack'

module Stoor
  class ReplaceContent
    include Rack::Utils

    attr_reader :pass_condition

    def initialize(app, regexp, string, pass_condition = ->(request, headers) { false })
      @app, @regexp, @string, @pass_condition = app, regexp, string, pass_condition
    end

    def call(env)
      status, headers, response = @app.call(env)
      request = Rack::Request.new(env)
      headers = HeaderHash.new(headers)

      if pass_condition.call(request, headers)
        if request.logger
          request.logger.info "Skipping -- because pass condition met"
        end
      else
        body = Array(response).join("").gsub(@regexp, @string)
        headers['Content-Length'] = body.bytesize.to_s
        return [ status, headers, [ body ] ]
      end

      [ status, headers, response ]
    end
  end
end

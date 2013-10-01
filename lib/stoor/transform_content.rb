require 'rack'

module Stoor
  class TransformContent
    include Rack::Utils

    attr_reader :status, :headers, :request
    attr_reader :app, :regexp, :content_type, :pass_condition

    def initialize(app, options)
      @app            = app
      @regexp         = options[:regexp]
      @before         = options[:before]
      @after          = options[:after]
      @content_type   = options[:content_type] || 'text/html'
      @pass_condition = options[:pass_condition] || ->(env) { false }
    end

    def call(env)
      @status, @headers, response = @app.call(env)
      @request = Rack::Request.new(env)

      if pass_condition.call(request)
        if request.logger
          request.logger.info "Skipping -- because pass condition met"
        end
      else
        @headers = HeaderHash.new(@headers)
        if has_body && not_encoded && headers['content-type'] && headers['content-type'].index(content_type)
          content = Array(response).join('')
          if match_data = content.match(regexp)
            new_body = interpolate(match_data)
            headers['Content-Length'] = new_body.bytesize.to_s
            return [status, headers, [new_body]]
          end
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

    def interpolate(match_data)
      # regexp: /<body>/
      #   result: before<body>after
      # regexp: /(<div>)(.*?)(<\/div)
      #   result: <div>beforezzzafter</div>
      "".tap do |s|
        s << match_data.pre_match
        if match_data.size == 1
          s << before + match_data[0] + after
        elsif match_data.size == 4
          s << match_data[1] + before + match_data[2] + after + match_data[3]
        else
          # Might just set the result to content?
          raise "Unexpected number of captures in #{match_data.regexp}"
        end
        s << match_data.post_match
      end
    end

    def before
      freshen(@before)
    end

    def after
      freshen(@after)
    end

    def freshen(e)
      if e.respond_to? :call
        e.call(request)
      else
        e.to_s
      end
    end
  end
end

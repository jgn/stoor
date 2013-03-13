module Stoor
  class Decorate
    include Rack::Utils

    FOOTER_REGEXP = /(<div id="footer">)(.*?)(<\/div>)/im

    def initialize(app); @app = app; end

    def call(env)
      @request = Rack::Request.new(env)

      if @request.session['gollum.author'].nil?
        puts "No 'gollum.author' in session - skipping page decoration."
        return @app.call(env)
      end

      status, headers, response = @app.call(env)
      headers = HeaderHash.new(headers)

      if !STATUS_WITH_NO_ENTITY_BODY.include?(status) &&
          !headers['transfer-encoding'] &&
          headers['content-type'] &&
          headers['content-type'].include?("text/html")

        # TODO: If the response isn't an Array, it's a Rack::File or something, so ignore
        if response.respond_to? :inject
          content = response.inject("") { |content, part| content << part }
          if match_data = content.match(FOOTER_REGEXP)
            new_body = "" <<
              match_data.pre_match <<
              match_data[1] <<
              before_existing_footer <<
              match_data[2] <<
              after_existing_footer <<
              match_data[3] <<
              match_data.post_match
            headers['Content-Length'] = new_body.bytesize.to_s
            return [status, headers, [new_body]]
          end
        end
      end

      [status, headers, response]
    end

    def before_existing_footer
      <<-HTML
        <div style="float: left;">
      HTML
    end

    def after_existing_footer
      <<-HTML
        </div>
        <div style="float: right;">
          <p style="text-align: right; font-size: .9em; line-height: 1.6em; color: #999; margin: 0.9em 0;">
            Commiting as <b>#{@request.session['gollum.author'][:name]}</b> (#{@request.session['gollum.author'][:email]})#{" | <a href='/logout'>Logout</a>" if ENV['GITHUB_AUTHORIZED']}
          </p>
        </div>
      HTML
    end
  end
end

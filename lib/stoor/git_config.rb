module Stoor
  class GitConfig
    def initialize(app); @app = app; end

    def call(env)
      @request = Rack::Request.new(env)
      unless @request.session['gollum.author']
        if ENV['WIKI_PATH_IN_USE']
          if name = git_option_value('user.name')
            if email = git_option_value('user.email')
              @request.session['gollum.author'] = { :name => name, :email => email }
            end
          end
        end
      end
      @app.call(env)
    end

    def git_option_value(option)
      `cd #{ENV['WIKI_PATH_IN_USE']} && git config --get #{option}`.strip
    rescue
    end
  end
end

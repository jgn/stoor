module Stoor
  class GitConfig
    attr_reader :repo_path

    def initialize(app, repo_path)
      @app, @repo_path = app, repo_path
    end

    def call(env)
      @request = Rack::Request.new(env)
      unless @request.session['gollum.author']
        if repo_path
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
      @repo ||= Grit::Repo.new(repo_path)
      @repo.config[option]
    end
  end
end

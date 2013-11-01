module Stoor
  class ReadOnly
    include Rack::Utils

    def initialize(app, path)
      @app, @path = app, path
    end

    def call(env)
      request = Rack::Request.new(env)

      if request.path_info =~ /\A\/(create|delete)/ || request.post? || request.put?
        return [302, { 'Location' => @path }, []]
      end

      @app.call(env)
    end
  end
end

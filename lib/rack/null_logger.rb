# Force the NullLogger to be a no-op, since it keeps getting bound into the
# Request instance.
module Rack
  class NullLogger
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    end
  end
end

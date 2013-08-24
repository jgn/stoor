# Like Rack::Logger, but provide for defining the stream
# at initialization.
module Stoor
  class Logger
    def initialize(app, stream = nil, level = ::Logger::INFO)
      @app, @stream, @level = app, stream, level
    end

    def call(env)
      stream = @stream || env['rack.errors']
      logger = ::Logger.new(stream)
      logger.level = @level

      env['rack.logger'] = logger
      @app.call(env)
    end
  end
end

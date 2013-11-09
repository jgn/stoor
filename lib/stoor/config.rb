require 'logger'

module Stoor
  class Config
    def initialize(file, running_via_cmd)
      @file, @running_via_cmd = file, running_via_cmd
    end

    def dirname
      @dirname ||= begin
        dirname = File.dirname(@file)
        dirname = `pwd`.chomp if dirname == '.'  # Probably being run by Apache
        dirname
      end
    end

    def env_prefix
      @env_prefix ||= begin
        @running_via_cmd ? 'STOOR' : dirname.split(File::SEPARATOR).last.upcase
      end
    end

    def env(token)
      ENV["#{env_prefix}_#{token}"]
    end

    def log(m)
      log_stream.write(m + "\n")
    end

    def log_frag
      @log_frag ||= "#{dirname}/log/#{ENV['RACK_ENV']}"
    end

    def access_logger
      @access_logger ||= begin
        access_logger = ::Logger.new("#{log_frag}_access.log")
        access_logger.instance_eval do
          def write(msg); self.send(:<<, msg); end
        end
        access_logger.level = ::Logger::INFO
        access_logger
      end
    end

    def log_stream
      @log_stream ||= begin
        log_stream = File.open("#{log_frag}.log", 'a+')
        log_stream.sync = true
        log_stream
      end
    end

    def dump_env
      log "#{env_prefix} env"
      ENV.each_pair do |k, v|
        log "  #{k}: #{v}" if k =~ /\A#{env_prefix}/
      end
    end

    def repo_missing?(path)
      Gollum::Wiki.new(path)
      return nil
    rescue Gollum::InvalidGitRepositoryError, Gollum::NoSuchPathError
      return "Sorry, #{path} is not a git repository; you might try `cd #{path}; git init .`."
    rescue NameError
      return "Sorry, #{path} doesn't exist; set the environment variable STOOR_WIKI_PATH to point to a git repository."
    end
  end
end

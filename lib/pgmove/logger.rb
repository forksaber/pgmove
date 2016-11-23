require_relative 'custom_logger'
module Pgmove
  module Logger

    class << self
      attr_writer :logger
    end

    def self.logger
      @logger ||= CustomLogger.new(STDOUT)
    end

    def self.stderr
      @stderr ||= ::Logger.new(STDERR)
    end

    def logger
      ::Pgmove::Logger.logger
    end

    def stderr
      ::Pgmove::Logger.stderr
    end

  end
end

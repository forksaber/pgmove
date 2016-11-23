require 'logger'
require_relative 'ext/string_ext'

module Pgmove
  class CustomLogger < ::Logger

    using StringExt
    attr_accessor :trace_mode

    def initialize(file)
      super(file)
      @level = ::Logger::INFO
    end

    def format_message(severity, timestamp, progname, msg)
      case severity
      when "INFO"
        "#{msg}\n"
      when "ERROR"
        "#{severity.bold.red} #{msg}\n"
      when "WARN"
        "#{severity.downcase.bold.yellow} #{msg}\n"
      else
        "#{severity[0].bold.blue} #{msg}\n"
      end
    end

    def bullet(msg)
      info "#{"\u2219".bold.blue} #{msg}"
    end

    def trace(msg)
      return if not @trace_mode
      info %(#{"T".bold.blue} #{msg}\n)
    end

    def silence!
      @logdev = nil
    end

  end
end

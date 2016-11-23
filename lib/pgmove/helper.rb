require_relative 'logger'

module Pgmove
  module Helper

    include Logger

    def system!(command, display: true, env: {})
      logger.bullet command if display
      ok = system env, command
      raise "Non zero exit: #{command}" if not ok
    end

  end
end

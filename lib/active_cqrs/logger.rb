require "logger"

module ActiveCqrs
  module Logger
    class << self
      attr_accessor :enabled

      def log(message)
        return unless enabled

        if defined?(Rails)
          ::Rails.logger.info("[CQRS] #{message}")
        else
          puts "[CQRS] #{message}"
        end
      end
    end

    self.enabled = true
  end
end

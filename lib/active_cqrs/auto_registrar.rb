require "active_cqrs/logger"

module ActiveCqrs
  class AutoRegistrar
    def initialize(command_bus:, query_bus:, root: Rails.root)
      @command_bus = command_bus
      @query_bus = query_bus
      @root = root
    end

    def call
      load_handlers
      register_handlers
    end

    private

    def load_handlers
      command_files = Dir[@root.join("app/handlers/commands/**/*.rb")]
      query_files   = Dir[@root.join("app/handlers/queries/**/*.rb")]

      (command_files + query_files).each do |file|
        require_dependency file
        Logger.log "Loaded handler file: #{file.gsub(@root.to_s + "/", "")}"
      end
    end

    def register_handlers
      ObjectSpace.each_object(Class).select { |klass| klass.name&.end_with?("Handler") }.each do |handler_class|
        next unless handler_class.name

        base_name = handler_class.name.sub(/Handler$/, "")
        command_class = safe_constantize("#{base_name}Command")
        query_class   = safe_constantize("#{base_name}Query")

        if command_class
          @command_bus.registry.register(command_class, handler_class.new)
          Logger.log "Registered #{handler_class} for #{command_class}"
        elsif query_class
          @query_bus.registry.register(query_class, handler_class.new)
          Logger.log "Registered #{handler_class} for #{query_class}"
        else
          Logger.log "Skipped #{handler_class} — no matching Command or Query class found"
        end
      end
    end

    def safe_constantize(name)
      Object.const_get(name)
    rescue NameError
      nil
    end
  end
end

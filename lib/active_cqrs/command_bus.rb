module ActiveCqrs
  class CommandBus
    attr_reader :registry

    def initialize(registry = HandlerRegistry.new)
      @registry = registry
    end

    def call(command)
      handler = @registry.resolve(command.class)
      handler.call(command)
    end
  end
end

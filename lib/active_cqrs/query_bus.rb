module ActiveCqrs
  class QueryBus
    attr_reader :registry

    def initialize(registry = HandlerRegistry.new)
      @registry = registry
    end

    def call(query)
      handler = @registry.resolve(query.class)
      handler.call(query)
    end
  end
end

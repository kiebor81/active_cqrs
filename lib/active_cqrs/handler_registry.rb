module ActiveCqrs
  class HandlerRegistry
    def initialize
      @handlers = {}
    end

    def register(klass, handler)
      @handlers[klass] = handler
    end

    def resolve(klass)
      @handlers[klass] || raise("No handler registered for #{klass}")
    end
  end
end

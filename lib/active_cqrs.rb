# frozen_string_literal: true

require "active_cqrs/version"
require "active_cqrs/command"
require "active_cqrs/query"
require "active_cqrs/command_bus"
require "active_cqrs/query_bus"
require "active_cqrs/handler_registry"
require "active_cqrs/logger"
require "active_cqrs/auto_registrar"
require "active_cqrs/railtie" if defined?(Rails)
require_relative "active_cqrs/version"

module ActiveCqrs
  class Error < StandardError; end
  # Your code goes here...
end

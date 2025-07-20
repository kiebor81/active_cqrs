# frozen_string_literal: true

require "active_cqrs"

Rails.application.config.to_prepare do
  CQRS_COMMAND_BUS = ActiveCqrs::CommandBus.new
  CQRS_QUERY_BUS   = ActiveCqrs::QueryBus.new

  ActiveCqrs::Logger.enabled = Rails.env.development?

  ActiveCqrs::AutoRegistrar.new(
    command_bus: CQRS_COMMAND_BUS,
    query_bus:   CQRS_QUERY_BUS
  ).call
end

require "rails/railtie"

module ActiveCQRS
  class Railtie < Rails::Railtie
    initializer "active_cqrs.configure" do |app|
      # Optionally inject configuration or generators
    end
  end
end

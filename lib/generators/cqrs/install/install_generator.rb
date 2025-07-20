require "rails/generators"

module Cqrs
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      desc "Creates a CQRS initializer"

      def copy_initializer
        template "initializer.rb", "config/initializers/cqrs.rb"
      end
    end
  end
end

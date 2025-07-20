require "rails/generators"

module Cqrs
  module Generators
    class CommandGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)
      desc "Generates a command and corresponding handler"

      def create_command_file
        template "command.rb.tt", File.join("app/commands", class_path, "#{file_name}_command.rb")
      end

      def create_handler_file
        template "command_handler.rb.tt", File.join("app/handlers/commands", class_path, "#{file_name}_handler.rb")
      end
    end
  end
end

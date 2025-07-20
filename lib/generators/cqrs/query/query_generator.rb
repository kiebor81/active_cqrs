require "rails/generators"

module Cqrs
  module Generators
    class QueryGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)
      desc "Generates a query and corresponding handler"

      def create_query_file
        template "query.rb.tt", File.join("app/queries", class_path, "#{file_name}_query.rb")
      end

      def create_handler_file
        template "query_handler.rb.tt", File.join("app/handlers/queries", class_path, "#{file_name}_handler.rb")
      end
    end
  end
end

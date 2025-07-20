# frozen_string_literal: true

require_relative "lib/active_cqrs/version"

Gem::Specification.new do |spec|
  spec.name = "active_cqrs"
  spec.version = ActiveCqrs::VERSION
  spec.authors = ["kiebor81"]
  spec.description = "active_cqrs is a lightweight Ruby gem that introduces CQRS into Rails applications"
  spec.homepage = "https://github.com/kiebor81/active_cqrs"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"
  spec.summary     = "CQRS interface for Rails using ActiveRecord"
  spec.files       = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
  spec.add_dependency "rails", ">= 6.0"

end

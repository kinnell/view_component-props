# frozen_string_literal: true

require_relative "lib/view_component_props/version"

Gem::Specification.new do |spec|
  spec.name = "view_component-props"
  spec.version = ViewComponentProps::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Kinnell Shah"]
  spec.email = ["kinnell@gmail.com"]

  spec.summary = "A ViewComponent extension for working with component props"
  spec.description = <<~TEXT
    A ViewComponent extension that adds a `prop` DSL with defaults, fallbacks, required props, casting, enum validation, custom validators, and a pluggable caster registry. Patches ViewComponent::Base via a Rails Railtie (or on require outside Rails) so components accept a props hash out of the box.
  TEXT

  spec.homepage = "https://github.com/kinnell/view_component-props"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["github_repo"] = "ssh://github.com/kinnell/view_component-props"
  spec.metadata["source_code_uri"] = "https://github.com/kinnell/view_component-props"
  spec.metadata["changelog_uri"] = "https://github.com/kinnell/view_component-props/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/kinnell/view_component-props/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "LICENSE", "*.md"]

  spec.require_paths = ["lib"]
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0")
  spec.required_rubygems_version = Gem::Requirement.new(">= 2.0")

  spec.add_dependency "activemodel", ">= 6.0", "< 9.0"
  spec.add_dependency "activesupport", ">= 6.0", "< 9.0"
  spec.add_dependency "view_component", ">= 3.0", "< 5.0"
end

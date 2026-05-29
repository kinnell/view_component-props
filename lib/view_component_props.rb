# frozen_string_literal: true

require "active_support/core_ext/class/attribute"
require "active_support/core_ext/hash/indifferent_access"
require "view_component"

require_relative "view_component_props/configuration"
require_relative "view_component_props/errors"
require_relative "view_component_props/casters"
require_relative "view_component_props/definition"
require_relative "view_component_props/definable"
require_relative "view_component_props/version"

module ViewComponentProps
  class << self
    def install!(target = ViewComponent::Base)
      return if target.include?(Definable)

      target.include(Definable)
      target.class_eval do
        def initialize(props = {})
          super()
          setup_props_for(props)
          after_initialize
        end
      end
    end
  end
end

if defined?(Rails::Railtie)
  require_relative "view_component_props/railtie"
elsif ViewComponentProps.configuration.auto_include
  ViewComponentProps.install!
end

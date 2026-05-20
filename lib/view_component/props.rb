# frozen_string_literal: true

require "active_support/core_ext/class/attribute"
require "active_support/core_ext/hash/indifferent_access"
require "view_component"

require_relative "props/configuration"
require_relative "props/errors"
require_relative "props/casters"
require_relative "props/definition"
require_relative "props/definable"
require_relative "props/version"

module ViewComponent
  module Props
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
end

if defined?(Rails::Railtie)
  require_relative "props/railtie"
elsif ViewComponent::Props.configuration.auto_include
  ViewComponent::Props.install!
end

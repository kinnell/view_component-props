# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/module/attribute_accessors"
require "bigdecimal"
require "date"
require "time"
require "active_model"
require "active_model/type"
require "active_model/type/boolean"

require_relative "configuration"

module ViewComponent
  module Props
    module Casters
      mattr_accessor :registry, default: HashWithIndifferentAccess.new

      class << self
        def fetch(key)
          registry.fetch(key)
        end

        def known?(key)
          registry.key?(key)
        end

        def reset!
          self.registry = Base.base_casters.merge(Props.configuration.custom_casters)
        end
      end
    end
  end
end

require_relative "casters/base"

ViewComponent::Props::Casters.reset!

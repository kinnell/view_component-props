# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"

module ViewComponentProps
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
      Casters.reset! if defined?(Casters)
    end
  end

  class Configuration
    attr_accessor :auto_include
    attr_accessor :reject_undefined_props
    attr_reader :custom_casters

    def initialize
      @auto_include = true
      @reject_undefined_props = false
      @custom_casters = HashWithIndifferentAccess.new
    end

    def register_caster(key, &block)
      raise ArgumentError, "register_caster requires a block" unless block

      custom_casters[key] = block
      Casters.registry[key] = block if defined?(Casters)
    end
  end
end

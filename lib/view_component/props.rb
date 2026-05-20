# frozen_string_literal: true

require "active_support/concern"
require "active_support/dependencies/autoload"
require "active_support/core_ext/hash/indifferent_access"
require "view_component"

require_relative "props/configuration"
require_relative "props/errors"
require_relative "props/version"

module ViewComponent
  module Props
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        @configuration = Configuration.new
      end
    end
  end
end

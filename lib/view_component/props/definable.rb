# frozen_string_literal: true

require "active_support/concern"

module ViewComponent
  module Props
    module Definable
      extend ActiveSupport::Concern

      included do
        class_attribute :prop_definitions, instance_accessor: false, default: HashWithIndifferentAccess.new
        class_attribute :undefined_props_rejected, instance_accessor: false, default: nil

        attr_reader :props
        attr_reader :raw_props
      end

      class_methods do
        def prop(key, options = {})
          definition = Definition.new(key, options, component: name)
          self.prop_definitions = prop_definitions.merge(key => definition)
        end

        def reject_undefined_props!
          self.undefined_props_rejected = true
        end

        def permit_undefined_props!
          self.undefined_props_rejected = false
        end
      end

      def setup_props_for(props)
        enforce_defined_props!(props) if undefined_props_rejected?

        indifferent_props = props.with_indifferent_access
        @raw_props = props.dup.freeze
        @props = resolve_props(indifferent_props).freeze
      end

      def after_initialize; end

      private

      def undefined_props_rejected?
        per_class_setting = self.class.undefined_props_rejected
        return per_class_setting unless per_class_setting.nil?

        ViewComponent::Props.configuration.reject_undefined_props
      end

      def enforce_defined_props!(props)
        declared_props = self.class.prop_definitions.keys.map(&:to_s)
        unknown_props = props.keys.map(&:to_s) - declared_props
        return if unknown_props.empty?

        raise UnknownPropsError, "Unknown props for #{self.class.name}: #{unknown_props.map(&:to_sym).inspect}"
      end

      def resolve_props(props)
        self.class.prop_definitions.each_with_object(props.dup) do |(key, definition), resolved|
          resolved[key] = definition.call(props, self)
        end
      end
    end
  end
end

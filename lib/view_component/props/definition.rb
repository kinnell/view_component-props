# frozen_string_literal: true

module ViewComponent
  module Props
    class Definition
      OPTION_KEYS = %i[
        default
        fallback
        required
        cast
        enum
        validate
        description
      ].freeze

      attr_reader :key, :description

      def initialize(key, options = {}, component:)
        @key = key
        @options = options
        @component = component

        validate_options!

        cast = normalize_cast(@options[:cast])
        @caster = build_caster(cast)
        @cast_label = describe_cast(cast)
        @required = @options[:required] || false
        @enum = @options[:enum]
        @validate = @options[:validate]
        @default = @options[:default]
        @fallback = @options[:fallback]
        @description = @options[:description]
      end

      def call(props, instance = nil)
        value = evaluate(props, instance)
        casted_value = cast_value(value)

        raise RequiredPropError, "Required prop :#{@key} for #{@component} cannot be nil" if casted_value.nil? && @required
        return casted_value if casted_value.nil?

        raise InvalidEnumValueError, "Prop :#{@key} for #{@component} must be one of #{@enum.inspect}, got #{casted_value.inspect}" if @enum && !@enum.include?(casted_value)
        raise ValidationFailedError, "Prop :#{@key} for #{@component} failed validation, got #{casted_value.inspect}" if @validate && !@validate.call(casted_value)

        casted_value
      end

      private

      def validate_options!
        unknown_keys = @options.keys - OPTION_KEYS
        raise UnknownOptionError, "Unknown options for prop :#{@key}: #{unknown_keys.inspect}" if unknown_keys.any?

        return unless @options.key?(:cast)

        cast_option = @options[:cast]
        raise UnknownCastError, "Cast type for prop :#{@key} cannot be nil" if cast_option.nil?
        return if cast_option.respond_to?(:call)
        return if cast_option.is_a?(Symbol) || cast_option.is_a?(String)

        raise UnknownCastError, "Cast type for prop :#{@key} must be a Symbol, String, or callable, got #{cast_option.inspect}"
      end

      def normalize_cast(value)
        return nil if value.nil?
        return value if value.respond_to?(:call)

        value.to_sym
      end

      def evaluate(props, instance)
        props = props.with_indifferent_access unless props.is_a?(HashWithIndifferentAccess)
        value = begin
          if props.key?(@key)
            props[@key]
          elsif @options.key?(:default)
            resolve(@default, instance)
          end
        end

        value = resolve(@fallback, instance) if value.nil? && @options.key?(:fallback)
        value
      end

      def build_caster(cast)
        return nil if cast.nil?
        return cast if cast.respond_to?(:call)

        ->(value) { Casters.fetch(cast).call(value) }
      end

      def cast_value(value)
        return value if value.nil? || @caster.nil?

        @caster.call(value)
      rescue ViewComponent::Props::Error
        raise
      rescue ArgumentError, TypeError, NoMethodError, KeyError, RangeError => e
        raise CastError, "Prop :#{@key} for #{@component} could not be cast to #{@cast_label} (got #{value.inspect}): #{e.message}"
      end

      def describe_cast(cast)
        return nil if cast.nil?
        return cast.inspect unless cast.respond_to?(:call)

        location = cast.respond_to?(:source_location) ? cast.source_location : nil
        location ? "callable at #{location.join(':')}" : "callable"
      end

      def resolve(value, instance)
        return value unless value.respond_to?(:call)

        instance ? instance.instance_exec(&value) : value.call
      end
    end
  end
end

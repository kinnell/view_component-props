# frozen_string_literal: true

module ViewComponent
  module Props
    module Casters
      class Base
        BOOLEAN_TYPE = ActiveModel::Type::Boolean.new

        class_attribute :base_casters, instance_accessor: false, default: HashWithIndifferentAccess.new

        def self.register_caster(key, &block)
          Casters.registry[key] = block
          self.base_casters = base_casters.merge(key => block)
        end

        register_caster(:integer) do |value|
          Integer(value)
        end

        register_caster(:float) do |value|
          Float(value)
        end

        register_caster(:string) do |value|
          value.to_s
        end

        register_caster(:symbol) do |value|
          value.to_sym
        end

        register_caster(:boolean) do |value|
          BOOLEAN_TYPE.cast(value)
        end

        register_caster(:array) do |value|
          Array(value)
        end

        register_caster(:hash) do |value|
          value.is_a?(Hash) ? value : value.to_h
        end

        register_caster(:decimal) do |value|
          value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s)
        end

        register_caster(:date) do |value|
          value.is_a?(Date) ? value : Date.parse(value.to_s)
        end

        register_caster(:datetime) do |value|
          if value.is_a?(Time) || value.is_a?(DateTime)
            value
          else
            Time.zone ? Time.zone.parse(value.to_s) : Time.parse(value.to_s)
          end
        end
      end
    end
  end
end

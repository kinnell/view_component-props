# frozen_string_literal: true

module ViewComponent
  module Props
    class Railtie < Rails::Railtie
      config.view_component_props = ActiveSupport::OrderedOptions.new
      config.view_component_props.auto_include = true

      initializer "view_component.props.install", after: :load_config_initializers do |application|
        ViewComponent::Props.install! if application.config.view_component_props.auto_include
      end
    end
  end
end

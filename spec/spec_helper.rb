# frozen_string_literal: true

require "active_support/core_ext/time/zones"
require "view_component_props"

ViewComponentProps.install! unless ViewComponent::Base.include?(ViewComponentProps::Definable)

Time.zone = "UTC"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
  config.pattern = "**/*.spec.rb"

  config.before do
    ViewComponentProps.reset_configuration!
  end
end

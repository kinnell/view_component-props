# frozen_string_literal: true

require "active_support/core_ext/time/zones"
require "view_component/props"

ViewComponent::Props.install! unless ViewComponent::Base.include?(ViewComponent::Props::Definable)

Time.zone = "UTC"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
  config.pattern = "**/*.spec.rb"

  config.before do
    ViewComponent::Props.reset_configuration!
  end
end

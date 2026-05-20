# frozen_string_literal: true

require "view_component/props"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
  config.pattern = "**/*.spec.rb"

  config.before { ViewComponent::Props.reset_configuration! }
end

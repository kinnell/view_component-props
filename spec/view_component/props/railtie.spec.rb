# frozen_string_literal: true

return unless defined?(Rails::Railtie)

require "rails/railtie"
require "view_component/props/railtie"

RSpec.describe ViewComponent::Props::Railtie do
  describe "config.view_component_props" do
    it "defaults :auto_include to true" do
      expect(described_class.config.view_component_props.auto_include).to be true
    end
  end
end

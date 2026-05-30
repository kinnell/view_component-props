# frozen_string_literal: true

require "rails/railtie"
require "view_component_props/railtie"

RSpec.describe ViewComponentProps::Railtie do
  describe "config.view_component_props" do
    it "defaults :auto_include to true" do
      expect(described_class.config.view_component_props.auto_include).to be true
    end
  end

  describe ".initializers" do
    let(:initializer_names) { described_class.initializers.map(&:name) }

    it "includes 'view_component_props.install'" do
      expect(initializer_names).to include("view_component_props.install")
    end
  end
end

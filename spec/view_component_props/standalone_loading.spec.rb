# frozen_string_literal: true

RSpec.describe "Standalone Loading" do
  def run_in_subprocess(script)
    IO.popen(["bundle", "exec", "ruby", "-Ilib", "-e", script], err: %i[child out], &:read)
  end

  describe "Dash-Named Entry Require" do
    let(:output) do
      run_in_subprocess(<<~RUBY)
        require "view_component-props"
        ViewComponentProps.install! unless ViewComponent::Base.include?(ViewComponentProps::Definable)
        puts ViewComponentProps::VERSION
        puts ViewComponent::Base.include?(ViewComponentProps::Definable)
      RUBY
    end

    it "loads the gem through the dash-named entry shim" do
      expect(output).to include(ViewComponentProps::VERSION)
    end

    it "installs Definable into ViewComponent::Base" do
      expect(output).to include("true")
    end
  end

  describe "Definable Standalone Require" do
    let(:output) do
      run_in_subprocess(<<~RUBY)
        require "view_component_props/definable"
        puts "loaded"
      RUBY
    end

    it "loads without view_component preloading ActiveSupport::Concern" do
      expect(output).to include("loaded")
    end
  end

  describe "Configuration Standalone Require" do
    let(:output) do
      run_in_subprocess(<<~RUBY)
        require "view_component_props/configuration"
        puts ViewComponentProps::Configuration.new.custom_casters.class
      RUBY
    end

    it "builds custom_casters without ActiveSupport preloaded" do
      expect(output).to include("ActiveSupport::HashWithIndifferentAccess")
    end
  end

  describe "Pre-Require Caster Configuration" do
    let(:output) do
      run_in_subprocess(<<~RUBY)
        require "view_component_props/configuration"
        ViewComponentProps.configure { |config| config.register_caster(:preloaded) { |value| value.to_s.upcase } }
        require "view_component_props/casters"
        puts ViewComponentProps::Casters.fetch(:preloaded).call("abc")
      RUBY
    end

    it "merges casters registered before the registry loads" do
      expect(output).to include("ABC")
    end
  end
end

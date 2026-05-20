# frozen_string_literal: true

RSpec.describe "Standalone Loading" do
  def run_in_subprocess(script)
    IO.popen(["bundle", "exec", "ruby", "-Ilib", "-e", script], err: %i[child out], &:read)
  end

  describe "Definable Standalone Require" do
    let(:output) do
      run_in_subprocess(<<~RUBY)
        require "view_component/props/definable"
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
        require "view_component/props/configuration"
        puts ViewComponent::Props::Configuration.new.custom_casters.class
      RUBY
    end

    it "builds custom_casters without ActiveSupport preloaded" do
      expect(output).to include("ActiveSupport::HashWithIndifferentAccess")
    end
  end

  describe "Pre-Require Caster Configuration" do
    let(:output) do
      run_in_subprocess(<<~RUBY)
        require "view_component/props/configuration"
        ViewComponent::Props.configure { |config| config.register_caster(:preloaded) { |value| value.to_s.upcase } }
        require "view_component/props/casters"
        puts ViewComponent::Props::Casters.fetch(:preloaded).call("abc")
      RUBY
    end

    it "merges casters registered before the registry loads" do
      expect(output).to include("ABC")
    end
  end
end

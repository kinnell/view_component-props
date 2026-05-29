# frozen_string_literal: true

RSpec.describe ViewComponentProps do
  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(ViewComponentProps::Configuration)
    end

    it "memoizes the Configuration instance" do
      expect(described_class.configuration).to equal(described_class.configuration)
    end

    it "defaults :auto_include to true" do
      expect(described_class.configuration.auto_include).to be true
    end

    it "defaults :reject_undefined_props to false" do
      expect(described_class.configuration.reject_undefined_props).to be false
    end
  end

  describe ".configure" do
    it "yields the Configuration instance" do
      expect { |block| described_class.configure(&block) }.to yield_with_args(ViewComponentProps::Configuration)
    end
  end

  describe "Configuration#register_caster" do
    before do
      described_class.configure do |config|
        config.register_caster(:reversed) { |value| value.to_s.reverse }
      end
    end

    it "registers a caster on the global registry" do
      expect(ViewComponentProps::Casters.fetch(:reversed).call("abc")).to eq("cba")
    end
  end

  describe ".reset_configuration!" do
    let!(:original_configuration) { described_class.configuration }

    before { described_class.reset_configuration! }

    it "replaces the Configuration with a fresh instance" do
      expect(described_class.configuration).not_to equal(original_configuration)
    end

    context "when custom casters were registered" do
      before do
        described_class.configure { |config| config.register_caster(:custom_thing) { |value| value } }
        described_class.reset_configuration!
      end

      it "clears custom casters from the live registry" do
        expect(ViewComponentProps::Casters.known?(:custom_thing)).to be false
      end
    end
  end

  ################################################################################
  ## Non-Rails install
  ################################################################################

  describe "Non-Rails Install" do
    it "includes Definable into ViewComponent::Base when the gem loads outside Rails" do
      expect(ViewComponent::Base.include?(ViewComponentProps::Definable)).to be true
    end

    context "when auto_include is disabled after require time" do
      before { described_class.configure { |config| config.auto_include = false } }

      it "remains installed" do
        expect(ViewComponent::Base.include?(ViewComponentProps::Definable)).to be true
      end
    end
  end

  ################################################################################
  ## .install!
  ################################################################################

  describe ".install!" do
    let(:fake_base) do
      Class.new do
        def self.name
          "FakeBase"
        end
      end
    end

    context "when called with a target class" do
      before { described_class.install!(fake_base) }

      it "includes Definable into the target" do
        expect(fake_base.include?(ViewComponentProps::Definable)).to be true
      end

      context "when the .prop DSL is used" do
        before { fake_base.prop(:title) }

        it "registers the prop on the target" do
          expect(fake_base.prop_definitions).to include(:title)
        end
      end

      context "when #initialize is redefined" do
        before { fake_base.class_eval { prop :title } }

        let(:instance) { fake_base.new(title: "Hello") }

        it "accepts a props hash" do
          expect(instance.props[:title]).to eq("Hello")
        end
      end
    end

    context "when called twice on the same target" do
      before do
        described_class.install!(fake_base)
        described_class.install!(fake_base)
      end

      it "is idempotent" do
        expect(fake_base.ancestors.count(ViewComponentProps::Definable)).to eq(1)
      end
    end
  end
end

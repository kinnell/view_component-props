# frozen_string_literal: true

RSpec.describe ViewComponent::Props do
  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(ViewComponent::Props::Configuration)
    end

    it "memoizes the Configuration instance" do
      expect(described_class.configuration).to equal(described_class.configuration)
    end
  end

  describe ".configure" do
    it "yields the Configuration instance" do
      expect { |block| described_class.configure(&block) }.to yield_with_args(ViewComponent::Props::Configuration)
    end
  end

  describe ".reset_configuration!" do
    let!(:original_configuration) { described_class.configuration }

    before { described_class.reset_configuration! }

    it "replaces the Configuration with a fresh instance" do
      expect(described_class.configuration).not_to equal(original_configuration)
    end
  end
end

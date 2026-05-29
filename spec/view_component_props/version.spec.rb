# frozen_string_literal: true

RSpec.describe ViewComponentProps do
  describe "VERSION" do
    it "is defined" do
      expect(described_class::VERSION).not_to be_nil
    end

    it "follows semantic versioning" do
      expect(described_class::VERSION).to match(%r{\A\d+\.\d+\.\d+\z})
    end
  end
end

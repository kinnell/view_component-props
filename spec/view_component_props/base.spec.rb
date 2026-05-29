# frozen_string_literal: true

RSpec.describe ViewComponent::Base do
  let(:component_class) do
    Class.new(described_class) do
      def self.name
        "TestComponent"
      end

      prop :title
      prop :count, cast: :integer
    end
  end

  ################################################################################
  ## #initialize
  ################################################################################

  describe "#initialize" do
    context "when props are passed as a positional hash" do
      let(:input) { { title: "Hello", count: "42" } }
      let(:instance) { component_class.new(input) }

      it "exposes the input via #raw_props" do
        expect(instance.raw_props).to eq(input)
      end

      it "exposes the resolved value for :title via #props" do
        expect(instance.props[:title]).to eq("Hello")
      end

      it "casts the resolved value for :count" do
        expect(instance.props[:count]).to eq(42)
      end

      it "freezes the resolved hash" do
        expect(instance.props).to be_frozen
      end
    end

    context "when props are passed as keyword arguments" do
      let(:instance) { component_class.new(title: "Hello", count: "42") }

      it "exposes the input via #raw_props" do
        expect(instance.raw_props).to eq({ title: "Hello", count: "42" })
      end

      it "exposes the resolved value for :title via #props" do
        expect(instance.props[:title]).to eq("Hello")
      end

      it "casts the resolved value for :count" do
        expect(instance.props[:count]).to eq(42)
      end
    end

    context "when no props are supplied" do
      let(:instance) { component_class.new }

      it "exposes an empty raw_props hash" do
        expect(instance.raw_props).to eq({})
      end
    end
  end

  ################################################################################
  ## #after_initialize
  ################################################################################

  describe "#after_initialize" do
    context "with the default no-op hook" do
      let(:instance) { component_class.new({ title: "Hello" }) }

      it "does not raise" do
        expect { instance }.not_to raise_error
      end
    end

    context "when a subclass overrides #after_initialize" do
      let(:subclass) do
        Class.new(component_class) do
          attr_reader :computed_title

          def after_initialize
            @computed_title = props[:title].upcase
          end
        end
      end
      let(:instance) { subclass.new({ title: "hello" }) }

      it "invokes the override after props are set" do
        expect(instance.computed_title).to eq("HELLO")
      end
    end
  end

  ################################################################################
  ## Required Props
  ################################################################################

  describe "Required Props" do
    let(:required_component) do
      Class.new(described_class) do
        def self.name
          "TestComponent"
        end

        prop :title, required: true
      end
    end

    context "when the required prop is supplied" do
      it "does not raise" do
        expect {
          required_component.new({ title: "Hello" })
        }.not_to raise_error
      end
    end

    context "when the required prop is missing" do
      it "raises a RequiredPropError" do
        expect {
          required_component.new({})
        }.to raise_error(ViewComponentProps::RequiredPropError, %r{Required prop :title for TestComponent cannot be nil})
      end
    end
  end
end

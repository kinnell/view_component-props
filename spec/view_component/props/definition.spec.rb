# frozen_string_literal: true

RSpec.describe ViewComponent::Props::Definition do
  let(:component_name) { "TestComponent" }

  ################################################################################
  ## #call
  ################################################################################

  describe "#call" do
    ################################################################################
    ## Basic value resolution
    ################################################################################

    describe "Basic Value Resolution" do
      context "when the prop key is present in props" do
        let(:definition) { described_class.new(:title, {}, component: component_name) }
        let(:output) { definition.call({ title: "Hello" }) }

        it "returns the value" do
          expect(output).to eq("Hello")
        end
      end

      context "when the prop key is missing from props" do
        let(:definition) { described_class.new(:title, {}, component: component_name) }
        let(:output) { definition.call({}) }

        it "returns nil" do
          expect(output).to be_nil
        end
      end

      context "when props use string keys and the prop key is a symbol" do
        let(:definition) { described_class.new(:title, {}, component: component_name) }
        let(:output) { definition.call({ "title" => "Hello" }) }

        it "resolves the value through indifferent access" do
          expect(output).to eq("Hello")
        end
      end
    end

    ################################################################################
    ## Default
    ################################################################################

    describe "Default Value Resolution" do
      context "when the prop key is missing" do
        let(:definition) { described_class.new(:title, { default: "fallback" }, component: component_name) }
        let(:output) { definition.call({}) }

        it "returns the default value" do
          expect(output).to eq("fallback")
        end
      end

      context "when the prop key is present" do
        let(:definition) { described_class.new(:title, { default: "fallback" }, component: component_name) }
        let(:output) { definition.call({ title: "explicit" }) }

        it "returns the explicit value" do
          expect(output).to eq("explicit")
        end
      end

      context "when the prop key is present with nil" do
        let(:definition) { described_class.new(:title, { default: "fallback" }, component: component_name) }
        let(:output) { definition.call({ title: nil }) }

        it "returns nil (default does not cover explicit nil)" do
          expect(output).to be_nil
        end
      end

      context "when the default is a callable" do
        let(:definition) { described_class.new(:title, { default: -> { "computed" } }, component: component_name) }
        let(:output) { definition.call({}) }

        it "evaluates the callable" do
          expect(output).to eq("computed")
        end
      end
    end

    ################################################################################
    ## Fallback
    ################################################################################

    describe "Fallback Value Resolution" do
      context "when the prop key is missing" do
        let(:definition) { described_class.new(:title, { fallback: "safe" }, component: component_name) }
        let(:output) { definition.call({}) }

        it "returns the fallback value" do
          expect(output).to eq("safe")
        end
      end

      context "when the prop key is present with nil" do
        let(:definition) { described_class.new(:title, { fallback: "safe" }, component: component_name) }
        let(:output) { definition.call({ title: nil }) }

        it "returns the fallback value" do
          expect(output).to eq("safe")
        end
      end

      context "when the prop key is present with a value" do
        let(:definition) { described_class.new(:title, { fallback: "safe" }, component: component_name) }
        let(:output) { definition.call({ title: "explicit" }) }

        it "returns the explicit value" do
          expect(output).to eq("explicit")
        end
      end

      context "when the fallback is a callable" do
        let(:definition) { described_class.new(:title, { fallback: -> { "computed" } }, component: component_name) }
        let(:output) { definition.call({ title: nil }) }

        it "evaluates the callable" do
          expect(output).to eq("computed")
        end
      end
    end

    ################################################################################
    ## Default + Fallback combined
    ################################################################################

    describe "Default + Fallback Combined" do
      context "when the prop key is missing" do
        let(:definition) { described_class.new(:title, { default: nil, fallback: "safe" }, component: component_name) }
        let(:output) { definition.call({}) }

        it "applies fallback after default resolves to nil" do
          expect(output).to eq("safe")
        end
      end
    end

    ################################################################################
    ## Instance-Aware Callables
    ################################################################################

    describe "Instance-Aware Callables" do
      let(:instance) do
        Class.new do
          def computed_value
            "from instance"
          end
        end.new
      end

      context "when a default callable receives an instance" do
        let(:definition) { described_class.new(:title, { default: -> { computed_value } }, component: component_name) }
        let(:output) { definition.call({}, instance) }

        it "returns the value from instance state" do
          expect(output).to eq("from instance")
        end
      end

      context "when a default callable receives no instance" do
        let(:definition) { described_class.new(:title, { default: -> { "computed" } }, component: component_name) }
        let(:output) { definition.call({}) }

        it "returns the value from the callable" do
          expect(output).to eq("computed")
        end
      end

      context "when a fallback callable receives an instance" do
        let(:definition) { described_class.new(:title, { fallback: -> { computed_value } }, component: component_name) }
        let(:output) { definition.call({ title: nil }, instance) }

        it "returns the value from instance state" do
          expect(output).to eq("from instance")
        end
      end

      context "when a fallback callable receives no instance" do
        let(:definition) { described_class.new(:title, { fallback: -> { "computed" } }, component: component_name) }
        let(:output) { definition.call({ title: nil }) }

        it "returns the value from the callable" do
          expect(output).to eq("computed")
        end
      end
    end

    ################################################################################
    ## Required
    ################################################################################

    describe "Required" do
      context "when the prop key is present" do
        let(:definition) { described_class.new(:title, { required: true }, component: component_name) }
        let(:output) { definition.call({ title: "Hello" }) }

        it "returns the value" do
          expect(output).to eq("Hello")
        end
      end

      context "when the prop key is missing" do
        let(:definition) { described_class.new(:title, { required: true }, component: component_name) }

        it "raises a RequiredPropError" do
          expect {
            definition.call({})
          }.to raise_error(ViewComponent::Props::RequiredPropError, %r{Required prop :title for TestComponent cannot be nil})
        end
      end

      context "when the prop key is present with nil" do
        let(:definition) { described_class.new(:title, { required: true }, component: component_name) }

        it "raises a RequiredPropError" do
          expect {
            definition.call({ title: nil })
          }.to raise_error(ViewComponent::Props::RequiredPropError, %r{Required prop :title for TestComponent cannot be nil})
        end
      end

      context "when the prop key is missing but a default is provided" do
        let(:definition) { described_class.new(:title, { required: true, default: "x" }, component: component_name) }
        let(:output) { definition.call({}) }

        it "returns the default" do
          expect(output).to eq("x")
        end

        it "does not raise" do
          expect { definition.call({}) }.not_to raise_error
        end
      end

      context "when the prop key is nil but a fallback is provided" do
        let(:definition) { described_class.new(:title, { required: true, fallback: "safe" }, component: component_name) }
        let(:output) { definition.call({ title: nil }) }

        it "returns the fallback" do
          expect(output).to eq("safe")
        end

        it "does not raise" do
          expect { definition.call({ title: nil }) }.not_to raise_error
        end
      end

      context "when the fallback itself resolves to nil" do
        let(:definition) { described_class.new(:title, { required: true, fallback: nil }, component: component_name) }

        it "raises a RequiredPropError (required wins over a nil fallback)" do
          expect {
            definition.call({ title: nil })
          }.to raise_error(ViewComponent::Props::RequiredPropError, %r{Required prop :title for TestComponent cannot be nil})
        end
      end

      context "when a lossy cast turns a present value into nil" do
        let(:definition) { described_class.new(:flag, { required: true, cast: :boolean }, component: component_name) }

        it "raises a RequiredPropError after casting" do
          expect {
            definition.call({ flag: "" })
          }.to raise_error(ViewComponent::Props::RequiredPropError, %r{Required prop :flag for TestComponent cannot be nil})
        end
      end

      context "when a callable cast returns nil for a present value" do
        let(:definition) { described_class.new(:flag, { required: true, cast: proc {} }, component: component_name) }

        it "raises a RequiredPropError after casting" do
          expect {
            definition.call({ flag: "present" })
          }.to raise_error(ViewComponent::Props::RequiredPropError, %r{Required prop :flag for TestComponent cannot be nil})
        end
      end
    end

    ################################################################################
    ## Cast
    ################################################################################

    describe "Cast Type Application" do
      context "with cast: :integer" do
        let(:definition) { described_class.new(:count, { cast: :integer }, component: component_name) }
        let(:output) { definition.call({ count: "42" }) }

        it "casts the value to an integer" do
          expect(output).to eq(42)
        end
      end

      context "with cast: 'integer'" do
        let(:definition) { described_class.new(:count, { cast: "integer" }, component: component_name) }
        let(:output) { definition.call({ count: "42" }) }

        it "casts the value to an integer" do
          expect(output).to eq(42)
        end
      end

      context "with cast: :float" do
        let(:definition) { described_class.new(:rate, { cast: :float }, component: component_name) }
        let(:output) { definition.call({ rate: "3.14" }) }

        it "casts the value to a float" do
          expect(output).to eq(3.14)
        end
      end

      context "with cast: :string" do
        let(:definition) { described_class.new(:label, { cast: :string }, component: component_name) }
        let(:output) { definition.call({ label: 123 }) }

        it "casts the value to a string" do
          expect(output).to eq("123")
        end
      end

      context "with cast: :symbol" do
        let(:definition) { described_class.new(:mode, { cast: :symbol }, component: component_name) }
        let(:output) { definition.call({ mode: "dark" }) }

        it "casts the value to a symbol" do
          expect(output).to eq(:dark)
        end
      end

      context "with cast: :boolean" do
        let(:definition) { described_class.new(:active, { cast: :boolean }, component: component_name) }

        context "when the value is truthy" do
          let(:output) { definition.call({ active: "1" }) }

          it "casts to true" do
            expect(output).to be true
          end
        end

        context "when the value is falsy" do
          let(:output) { definition.call({ active: "0" }) }

          it "casts to false" do
            expect(output).to be false
          end
        end
      end

      context "with cast: :array" do
        let(:definition) { described_class.new(:items, { cast: :array }, component: component_name) }
        let(:output) { definition.call({ items: "solo" }) }

        it "wraps the value in an array" do
          expect(output).to eq(["solo"])
        end
      end

      context "when the value is nil" do
        let(:definition) { described_class.new(:count, { cast: :integer }, component: component_name) }
        let(:output) { definition.call({ count: nil }) }

        it "returns nil without casting" do
          expect(output).to be_nil
        end
      end

      context "when a default is supplied with a cast" do
        let(:definition) { described_class.new(:mode, { cast: :symbol, default: "dark" }, component: component_name) }
        let(:output) { definition.call({}) }

        it "casts the default value" do
          expect(output).to eq(:dark)
        end
      end

      context "when a fallback is supplied with a cast" do
        let(:definition) { described_class.new(:mode, { cast: :symbol, fallback: "dark" }, component: component_name) }
        let(:output) { definition.call({ mode: nil }) }

        it "casts the fallback value" do
          expect(output).to eq(:dark)
        end
      end

      context "with cast: :array and a nil value" do
        let(:definition) { described_class.new(:items, { cast: :array }, component: component_name) }
        let(:output) { definition.call({ items: nil }) }

        it "passes nil through without casting" do
          expect(output).to be_nil
        end
      end

      context "with cast: :hash" do
        let(:definition) { described_class.new(:config, { cast: :hash }, component: component_name) }

        context "when the value is already a hash" do
          let(:output) { definition.call({ config: { a: 1 } }) }

          it "returns the hash unchanged (with indifferent access)" do
            expect(output).to eq({ a: 1 }.with_indifferent_access)
          end
        end

        context "when the value is an array of pairs" do
          let(:output) { definition.call({ config: [[:a, 1]] }) }

          it "converts it to a hash" do
            expect(output).to eq({ a: 1 })
          end
        end
      end

      context "with cast: :decimal" do
        let(:definition) { described_class.new(:price, { cast: :decimal }, component: component_name) }

        context "when the value is a numeric string" do
          let(:output) { definition.call({ price: "3.50" }) }

          it "parses it to a BigDecimal" do
            expect(output).to eq(BigDecimal("3.50"))
          end
        end

        context "when the value is already a BigDecimal" do
          let(:value) { BigDecimal("9.99") }
          let(:output) { definition.call({ price: value }) }

          it "returns it untouched" do
            expect(output).to equal(value)
          end
        end
      end

      context "with cast: :date" do
        let(:definition) { described_class.new(:starts_on, { cast: :date }, component: component_name) }

        context "when the value is an ISO-8601 date string" do
          let(:output) { definition.call({ starts_on: "2026-05-20" }) }

          it "parses it to a Date" do
            expect(output).to eq(Date.new(2026, 5, 20))
          end
        end

        context "when the value is already a Date" do
          let(:date) { Date.new(2026, 1, 1) }
          let(:output) { definition.call({ starts_on: date }) }

          it "returns it untouched" do
            expect(output).to equal(date)
          end
        end
      end

      context "with cast: :datetime" do
        let(:definition) { described_class.new(:starts_at, { cast: :datetime }, component: component_name) }

        context "when the value is an ISO-8601 datetime string" do
          let(:output) { definition.call({ starts_at: "2026-05-20T12:00:00Z" }) }

          it "parses it to a Time-like value" do
            expect(output).to be_a(ActiveSupport::TimeWithZone).or be_a(Time)
          end

          it "preserves the year" do
            expect(output.year).to eq(2026)
          end
        end

        context "when the value is already a Time" do
          let(:time) { Time.zone.local(2026, 5, 20, 12) }
          let(:output) { definition.call({ starts_at: time }) }

          it "returns it untouched" do
            expect(output).to equal(time)
          end
        end
      end

      context "with a callable cast" do
        let(:definition) { described_class.new(:slug, { cast: ->(value) { value.to_s.upcase } }, component: component_name) }
        let(:output) { definition.call({ slug: "hello" }) }

        it "invokes the callable to cast the value" do
          expect(output).to eq("HELLO")
        end
      end

      context "when a registered custom caster is used" do
        let(:definition) { described_class.new(:label, { cast: :reversed }, component: component_name) }
        let(:output) { definition.call({ label: "abc" }) }

        before do
          ViewComponent::Props.configure { |config| config.register_caster(:reversed) { |value| value.to_s.reverse } }
        end

        it "dispatches to the registered caster" do
          expect(output).to eq("cba")
        end
      end

      context "when a cast raises a low-level error" do
        let(:definition) { described_class.new(:count, { cast: :integer }, component: component_name) }

        it "wraps the error with prop and component context" do
          expect {
            definition.call({ count: "abc" })
          }.to raise_error(ViewComponent::Props::CastError, %r{Prop :count for TestComponent could not be cast to :integer \(got "abc"\)})
        end
      end

      context "when :hash casting a scalar raises a NoMethodError" do
        let(:definition) { described_class.new(:config, { cast: :hash }, component: component_name) }

        it "wraps it as a CastError" do
          expect {
            definition.call({ config: "nope" })
          }.to raise_error(ViewComponent::Props::CastError, %r{Prop :config for TestComponent could not be cast to :hash})
        end
      end

      context "when a cast raises a RangeError" do
        let(:definition) { described_class.new(:count, { cast: :integer }, component: component_name) }

        it "wraps it as a CastError" do
          expect {
            definition.call({ count: Float::INFINITY })
          }.to raise_error(ViewComponent::Props::CastError, %r{Prop :count for TestComponent could not be cast to :integer})
        end
      end

      context "when a callable cast raises a low-level error" do
        let(:definition) { described_class.new(:count, { cast: ->(_) { Integer("abc") } }, component: component_name) }

        it "wraps it as a CastError describing the callable" do
          expect {
            definition.call({ count: "anything" })
          }.to raise_error(ViewComponent::Props::CastError, %r{Prop :count for TestComponent could not be cast to callable})
        end
      end

      context "when a callable cast object does not expose a source location" do
        let(:callable_without_source_location) do
          Class.new do
            def call(_value)
              Integer("abc")
            end
          end.new
        end
        let(:definition) { described_class.new(:count, { cast: callable_without_source_location }, component: component_name) }

        it "labels the cast as a generic callable in the CastError" do
          expect {
            definition.call({ count: "anything" })
          }.to raise_error(ViewComponent::Props::CastError, %r{Prop :count for TestComponent could not be cast to callable \(})
        end
      end

      context "with a nil value and a callable cast" do
        let(:definition) { described_class.new(:items, { cast: ->(value) { Array(value) } }, component: component_name) }
        let(:output) { definition.call({ items: nil }) }

        it "passes nil through a callable cast untouched" do
          expect(output).to be_nil
        end
      end
    end

    ################################################################################
    ## Cast Error Propagation
    ################################################################################

    describe "Cast Error Propagation" do
      context "when a registered caster raises a ViewComponent::Props::Error" do
        let(:definition) { described_class.new(:label, { cast: :strict_label }, component: component_name) }

        before do
          ViewComponent::Props.configure do |config|
            config.register_caster(:strict_label) { |_| raise ViewComponent::Props::CastError, "strict rejection" }
          end
        end

        it "raises CastError with the original message" do
          expect {
            definition.call({ label: "abc" })
          }.to raise_error(ViewComponent::Props::CastError, "strict rejection")
        end
      end

      context "when a callable cast raises a ViewComponent::Props::Error" do
        let(:definition) do
          described_class.new(:label, { cast: ->(_) { raise ViewComponent::Props::CastError, "callable rejection" } }, component: component_name)
        end

        it "raises CastError with the original message" do
          expect {
            definition.call({ label: "abc" })
          }.to raise_error(ViewComponent::Props::CastError, "callable rejection")
        end
      end
    end

    ################################################################################
    ## Enum
    ################################################################################

    describe "Enum Value Restriction" do
      context "when the value is in the enum" do
        let(:definition) { described_class.new(:size, { enum: %i[small medium large] }, component: component_name) }
        let(:output) { definition.call({ size: :medium }) }

        it "returns the value" do
          expect(output).to eq(:medium)
        end
      end

      context "when the value is not in the enum" do
        let(:definition) { described_class.new(:size, { enum: %i[small medium large] }, component: component_name) }

        it "raises an InvalidEnumValueError" do
          expect {
            definition.call({ size: :huge })
          }.to raise_error(ViewComponent::Props::InvalidEnumValueError, %r{Prop :size for TestComponent must be one of})
        end
      end

      context "when the enum is checked against a casted value" do
        let(:definition) { described_class.new(:size, { cast: :symbol, enum: %i[small medium large] }, component: component_name) }
        let(:output) { definition.call({ size: "medium" }) }

        it "returns the casted value" do
          expect(output).to eq(:medium)
        end
      end
    end

    ################################################################################
    ## Validate
    ################################################################################

    describe "Custom Callable Validation" do
      let(:positive_number) { lambda(&:positive?) }

      context "when validation passes" do
        let(:definition) { described_class.new(:amount, { validate: positive_number }, component: component_name) }
        let(:output) { definition.call({ amount: 10 }) }

        it "returns the value" do
          expect(output).to eq(10)
        end
      end

      context "when validation fails" do
        let(:definition) { described_class.new(:amount, { validate: positive_number }, component: component_name) }

        it "raises a ValidationFailedError" do
          expect {
            definition.call({ amount: -1 })
          }.to raise_error(ViewComponent::Props::ValidationFailedError, %r{Prop :amount for TestComponent failed validation})
        end
      end

      context "when validation runs against the casted value" do
        let(:definition) { described_class.new(:amount, { cast: :integer, validate: positive_number }, component: component_name) }
        let(:output) { definition.call({ amount: "10" }) }

        it "returns the casted value" do
          expect(output).to eq(10)
        end
      end
    end
  end

  ################################################################################
  ## Option Validation
  ################################################################################

  describe "Unknown Prop Option Rejection" do
    it "raises an UnknownOptionError for unknown options" do
      expect {
        described_class.new(:title, { bogus: true }, component: component_name)
      }.to raise_error(ViewComponent::Props::UnknownOptionError, %r{Unknown options for prop :title})
    end

    it "raises an UnknownCastError for cast: nil" do
      expect {
        described_class.new(:title, { cast: nil }, component: component_name)
      }.to raise_error(ViewComponent::Props::UnknownCastError, %r{Cast type for prop :title cannot be nil})
    end

    it "accepts an unregistered symbol cast at definition time" do
      expect {
        described_class.new(:title, { cast: :nope }, component: component_name)
      }.not_to raise_error
    end

    it "defers an unregistered cast to render and raises a CastError" do
      definition = described_class.new(:title, { cast: :nope }, component: component_name)

      expect {
        definition.call({ title: "value" })
      }.to raise_error(ViewComponent::Props::CastError, %r{Prop :title for TestComponent could not be cast to :nope})
    end

    it "raises an UnknownCastError for a non-symbol, non-callable cast type" do
      expect {
        described_class.new(:title, { cast: 42 }, component: component_name)
      }.to raise_error(ViewComponent::Props::UnknownCastError, %r{must be a Symbol, String, or callable})
    end

    it "accepts a callable cast without raising" do
      expect {
        described_class.new(:title, { cast: lambda(&:to_s) }, component: component_name)
      }.not_to raise_error
    end

    it "accepts a string cast type without raising" do
      expect {
        described_class.new(:title, { cast: "integer" }, component: component_name)
      }.not_to raise_error
    end
  end

  ################################################################################
  ## #description
  ################################################################################

  describe "#description" do
    context "when :description is supplied" do
      let(:definition) { described_class.new(:variant, { description: "Visual treatment" }, component: component_name) }
      let(:output) { definition.description }

      it "returns the description string" do
        expect(output).to eq("Visual treatment")
      end
    end

    context "when :description is omitted" do
      let(:definition) { described_class.new(:variant, {}, component: component_name) }
      let(:output) { definition.description }

      it "returns nil" do
        expect(output).to be_nil
      end
    end
  end
end

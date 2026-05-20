# frozen_string_literal: true

RSpec.describe ViewComponent::Props::Casters do
  ################################################################################
  ## Custom Caster Registration
  ################################################################################

  describe "Custom Caster Registration" do
    def register_caster(...)
      ViewComponent::Props.configure { |config| config.register_caster(...) }
    end

    context "when called with a block" do
      before { register_caster(:reversed) { |value| value.to_s.reverse } }

      let(:output) { described_class.fetch(:reversed).call("abc") }

      it "casts values using the registered block" do
        expect(output).to eq("cba")
      end
    end

    context "when called without a block" do
      it "raises an ArgumentError" do
        expect {
          ViewComponent::Props.configure { |config| config.register_caster(:noop) }
        }.to raise_error(ArgumentError, %r{register_caster requires a block})
      end
    end

    context "when called with a string key" do
      before { register_caster("upcased") { |value| value.to_s.upcase } }

      let(:output) { described_class.fetch("upcased").call("abc") }

      it "casts values using the registered block" do
        expect(output).to eq("ABC")
      end
    end

    context "when overriding a built-in caster" do
      before do
        register_caster(:integer) { |value| value.to_i * 2 }
      end

      let(:output) { described_class.fetch(:integer).call("21") }

      it "uses the custom casting behavior" do
        expect(output).to eq(42)
      end

      context "after reset!" do
        before { described_class.reset! }

        let(:output) { described_class.fetch(:integer).call("21") }

        it "retains the configured override" do
          expect(output).to eq(42)
        end
      end
    end
  end

  ################################################################################
  ## .known?
  ################################################################################

  describe ".known?" do
    context "with a built-in key" do
      it "returns true" do
        expect(described_class.known?(:integer)).to be true
      end
    end

    context "with an unregistered key" do
      it "returns false" do
        expect(described_class.known?(:nope)).to be false
      end
    end
  end

  ################################################################################
  ## .fetch
  ################################################################################

  describe ".fetch" do
    context "with a registered key" do
      let(:output) { described_class.fetch(:integer).call("42") }

      it "returns a callable that casts values" do
        expect(output).to eq(42)
      end
    end

    context "with an unregistered key" do
      it "raises a KeyError" do
        expect {
          described_class.fetch(:nope)
        }.to raise_error(KeyError)
      end
    end
  end

  ################################################################################
  ## Built-In Casters
  ################################################################################

  describe "Built-In Casters" do
    ############################################################################
    ## :integer
    ############################################################################

    context "when :key is 'integer'" do
      let(:caster) { described_class.fetch(:integer) }

      context "with a numeric string" do
        let(:output) { caster.call("42") }

        it "parses to an Integer" do
          expect(output).to eq(42)
        end
      end

      context "with a negative numeric string" do
        let(:output) { caster.call("-7") }

        it "parses to a negative Integer" do
          expect(output).to eq(-7)
        end
      end

      context "with an Integer value" do
        let(:output) { caster.call(99) }

        it "returns the Integer unchanged" do
          expect(output).to eq(99)
        end
      end
    end

    ############################################################################
    ## :float
    ############################################################################

    context "when :key is 'float'" do
      let(:caster) { described_class.fetch(:float) }

      context "with a decimal string" do
        let(:output) { caster.call("3.14") }

        it "parses to a Float" do
          expect(output).to eq(3.14)
        end
      end

      context "with an integer string" do
        let(:output) { caster.call("10") }

        it "parses to a Float" do
          expect(output).to eq(10.0)
        end
      end

      context "with a numeric value" do
        let(:output) { caster.call(2) }

        it "converts to a Float" do
          expect(output).to eq(2.0)
        end
      end
    end

    ############################################################################
    ## :string
    ############################################################################

    context "when :key is 'string'" do
      let(:caster) { described_class.fetch(:string) }

      context "with an Integer value" do
        let(:output) { caster.call(123) }

        it "converts to a String" do
          expect(output).to eq("123")
        end
      end

      context "with a Symbol value" do
        let(:output) { caster.call(:foo) }

        it "converts to a String" do
          expect(output).to eq("foo")
        end
      end

      context "with a String value" do
        let(:output) { caster.call("hello") }

        it "returns the String unchanged" do
          expect(output).to eq("hello")
        end
      end
    end

    ############################################################################
    ## :symbol
    ############################################################################

    context "when :key is 'symbol'" do
      let(:caster) { described_class.fetch(:symbol) }

      context "with a String value" do
        let(:output) { caster.call("dark") }

        it "converts to a Symbol" do
          expect(output).to eq(:dark)
        end
      end

      context "with an existing Symbol" do
        let(:output) { caster.call(:light) }

        it "returns the Symbol unchanged" do
          expect(output).to eq(:light)
        end
      end
    end

    ############################################################################
    ## :boolean
    ############################################################################

    context "when :key is 'boolean'" do
      let(:caster) { described_class.fetch(:boolean) }

      context "with a truthy string '1'" do
        let(:output) { caster.call("1") }

        it "returns true" do
          expect(output).to be true
        end
      end

      context "with a truthy string 'true'" do
        let(:output) { caster.call("true") }

        it "returns true" do
          expect(output).to be true
        end
      end

      context "with a falsy string '0'" do
        let(:output) { caster.call("0") }

        it "returns false" do
          expect(output).to be false
        end
      end

      context "with a falsy string 'false'" do
        let(:output) { caster.call("false") }

        it "returns false" do
          expect(output).to be false
        end
      end
    end

    ############################################################################
    ## :array
    ############################################################################

    context "when :key is 'array'" do
      let(:caster) { described_class.fetch(:array) }

      context "with a scalar value" do
        let(:output) { caster.call("solo") }

        it "wraps it in an Array" do
          expect(output).to eq(["solo"])
        end
      end

      context "with an existing Array" do
        let(:output) { caster.call(%w[a b]) }

        it "returns the Array unchanged" do
          expect(output).to eq(%w[a b])
        end
      end
    end

    ############################################################################
    ## :hash
    ############################################################################

    context "when :key is 'hash'" do
      let(:caster) { described_class.fetch(:hash) }

      context "with an existing Hash" do
        let(:output) { caster.call({ a: 1 }) }

        it "returns the Hash unchanged" do
          expect(output).to eq({ a: 1 })
        end
      end

      context "with an Array of pairs" do
        let(:output) { caster.call([[:a, 1], [:b, 2]]) }

        it "converts to a Hash" do
          expect(output).to eq({ a: 1, b: 2 })
        end
      end
    end

    ############################################################################
    ## :decimal
    ############################################################################

    context "when :key is 'decimal'" do
      let(:caster) { described_class.fetch(:decimal) }

      context "with a numeric string" do
        let(:output) { caster.call("3.50") }

        it "parses to a BigDecimal" do
          expect(output).to eq(BigDecimal("3.50"))
        end
      end

      context "with an Integer value" do
        let(:output) { caster.call(5) }

        it "converts to a BigDecimal" do
          expect(output).to eq(BigDecimal("5"))
        end
      end

      context "with an existing BigDecimal" do
        let(:value) { BigDecimal("9.99") }
        let(:output) { caster.call(value) }

        it "returns the same instance" do
          expect(output).to equal(value)
        end
      end
    end

    ############################################################################
    ## :date
    ############################################################################

    context "when :key is 'date'" do
      let(:caster) { described_class.fetch(:date) }

      context "with an ISO-8601 string" do
        let(:output) { caster.call("2026-05-20") }

        it "parses to a Date" do
          expect(output).to eq(Date.new(2026, 5, 20))
        end
      end

      context "with an existing Date" do
        let(:date) { Date.new(2026, 1, 1) }
        let(:output) { caster.call(date) }

        it "returns the same instance" do
          expect(output).to equal(date)
        end
      end
    end

    ############################################################################
    ## :datetime
    ############################################################################

    context "when :key is 'datetime'" do
      let(:caster) { described_class.fetch(:datetime) }

      context "with an ISO-8601 datetime string" do
        let(:output) { caster.call("2026-05-20T12:00:00Z") }

        it "parses to a Time-like value" do
          expect(output).to be_a(ActiveSupport::TimeWithZone).or be_a(Time)
        end

        it "preserves the year" do
          expect(output.year).to eq(2026)
        end
      end

      context "with an existing Time" do
        let(:time) { Time.zone.local(2026, 5, 20, 12) }
        let(:output) { caster.call(time) }

        it "returns the same instance" do
          expect(output).to equal(time)
        end
      end

      context "with an existing DateTime" do
        let(:datetime) { DateTime.new(2026, 5, 20, 12) }
        let(:output) { caster.call(datetime) }

        it "returns the same instance" do
          expect(output).to equal(datetime)
        end
      end

      context "when Time.zone is nil" do
        around do |example|
          original_zone = Time.zone
          Time.zone = nil
          example.run
          Time.zone = original_zone
        end

        let(:output) { caster.call("2026-05-20T12:00:00Z") }

        it "falls back to Time.parse and returns a Time" do
          expect(output).to be_a(Time)
        end

        it "preserves the year" do
          expect(output.year).to eq(2026)
        end
      end
    end
  end

  ################################################################################
  ## .reset!
  ################################################################################

  describe ".reset!" do
    context "when the live registry was mutated outside the configuration" do
      before { described_class.registry[:ephemeral] = ->(value) { value } }

      context "after reset!" do
        before { described_class.reset! }

        it "removes the unbacked caster" do
          expect(described_class.known?(:ephemeral)).to be false
        end
      end
    end

    context "when a custom caster is registered through configuration" do
      before do
        ViewComponent::Props.configure { |config| config.register_caster(:custom_thing) { |value| value } }
        described_class.registry[:custom_thing] = ->(_) { :mutated }
        described_class.reset!
      end

      let(:output) { described_class.fetch(:custom_thing).call("input") }

      it "restores the configured casting behavior" do
        expect(output).to eq("input")
      end
    end

    context "after configuration is reset" do
      before do
        ViewComponent::Props.configure { |config| config.register_caster(:custom_thing) { |value| value } }
        ViewComponent::Props.reset_configuration!
      end

      it "does not restore custom casters from the previous configuration" do
        expect(described_class.known?(:custom_thing)).to be false
      end
    end

    context "when restoring built-in casters" do
      before { described_class.reset! }

      let(:output) { described_class.fetch(:integer).call("42") }

      it "casts using the built-in integer caster" do
        expect(output).to eq(42)
      end
    end
  end
end

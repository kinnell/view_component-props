# frozen_string_literal: true

RSpec.describe ViewComponent::Props::Definable do
  let(:test_model) do
    Class.new do
      include ViewComponent::Props::Definable

      def self.name
        "TestComponent"
      end

      def initialize(props = {})
        setup_props_for(props)
      end
    end
  end

  ################################################################################
  ## .prop
  ################################################################################

  describe ".prop" do
    context "when registering a valid prop" do
      before { test_model.class_eval { prop :title, default: "Hello" } }

      let(:output) { test_model.new({}).props[:title] }

      it "registers the prop for resolution" do
        expect(test_model.prop_definitions).to include(:title)
      end

      it "resolves the registered prop" do
        expect(output).to eq("Hello")
      end
    end

    context "when registering multiple props" do
      before do
        test_model.class_eval do
          prop :title
          prop :subtitle
        end
      end

      it "registers each prop independently" do
        expect(test_model.prop_definitions.keys).to contain_exactly("title", "subtitle")
      end
    end

    it "raises an UnknownOptionError for unknown options" do
      expect {
        test_model.class_eval { prop :title, bogus: true }
      }.to raise_error(ViewComponent::Props::UnknownOptionError, %r{Unknown options for prop :title})
    end
  end

  ################################################################################
  ## .reject_undefined_props!
  ################################################################################

  describe ".reject_undefined_props!" do
    context "when .reject_undefined_props! is not enabled" do
      before { test_model.class_eval { prop :title } }

      let(:instance) { test_model.new(title: "Hello", unknown: "extra") }

      it "preserves the undeclared key on #props" do
        expect(instance.props[:unknown]).to eq("extra")
      end
    end

    context "when .reject_undefined_props! is enabled" do
      before do
        test_model.class_eval do
          reject_undefined_props!
          prop :title
        end
      end

      it "raises an UnknownPropsError when an undeclared key is supplied" do
        expect {
          test_model.new(title: "Hello", unknown: "extra")
        }.to raise_error(ViewComponent::Props::UnknownPropsError, %r{Unknown props for TestComponent: \[:unknown\]})
      end

      context "when all keys are declared" do
        let(:instance) { test_model.new(title: "Hello") }

        it "does not raise" do
          expect { test_model.new(title: "Hello") }.not_to raise_error
        end

        it "resolves the declared prop" do
          expect(instance.props[:title]).to eq("Hello")
        end
      end

      context "when a string key supplies a declared prop" do
        let(:instance) { test_model.new("title" => "Hello") }

        it "does not raise" do
          expect { test_model.new("title" => "Hello") }.not_to raise_error
        end

        it "resolves the declared prop" do
          expect(instance.props[:title]).to eq("Hello")
        end
      end
    end
  end

  ################################################################################
  ## .permit_undefined_props!
  ################################################################################

  describe ".permit_undefined_props!" do
    context "when configuration enables :reject_undefined_props but the class permits them" do
      before do
        ViewComponent::Props.configure { |config| config.reject_undefined_props = true }
        test_model.class_eval do
          permit_undefined_props!
          prop :title
        end
      end

      let(:instance) { test_model.new(title: "Hello", unknown: "extra") }

      it "does not raise on unknown keys" do
        expect { test_model.new(title: "Hello", unknown: "extra") }.not_to raise_error
      end

      it "preserves the undeclared key on #props" do
        expect(instance.props[:unknown]).to eq("extra")
      end
    end
  end

  ################################################################################
  ## Configuration-Driven :reject_undefined_props
  ################################################################################

  describe "Configuration-Driven :reject_undefined_props" do
    before do
      ViewComponent::Props.configure { |config| config.reject_undefined_props = true }
      test_model.class_eval { prop :title }
    end

    context "when the class has no per-class override" do
      it "raises an UnknownPropsError for undeclared keys" do
        expect {
          test_model.new(title: "Hello", unknown: "extra")
        }.to raise_error(ViewComponent::Props::UnknownPropsError)
      end
    end

    context "when all keys are declared" do
      let(:instance) { test_model.new(title: "Hello") }

      it "does not raise" do
        expect { test_model.new(title: "Hello") }.not_to raise_error
      end

      it "resolves the declared prop" do
        expect(instance.props[:title]).to eq("Hello")
      end
    end
  end

  ################################################################################
  ## #setup_props_for
  ################################################################################

  describe "#setup_props_for" do
    before do
      test_model.class_eval do
        prop :title
        prop :count, cast: :integer
      end
    end

    describe "Raw Props" do
      let(:input) { { title: "Hello", count: "42" } }
      let(:instance) { test_model.new(input) }

      it "exposes the input via #raw_props" do
        expect(instance.raw_props).to eq(input)
      end

      it "freezes the raw input snapshot" do
        expect(instance.raw_props).to be_frozen
      end

      context "when the caller mutates the input hash after construction" do
        let!(:instance) { test_model.new(input) }

        before { input[:title] = "Changed" }

        it "isolates #raw_props from the mutation" do
          expect(instance.raw_props[:title]).to eq("Hello")
        end
      end
    end

    describe "Resolved Props" do
      let(:instance) { test_model.new(title: "Hello", count: "42") }

      it "exposes the resolved value for :title" do
        expect(instance.props[:title]).to eq("Hello")
      end

      it "casts the resolved value for :count" do
        expect(instance.props[:count]).to eq(42)
      end

      it "freezes the resolved hash" do
        expect(instance.props).to be_frozen
      end

      it "allows string-key access" do
        expect(instance.props["title"]).to eq("Hello")
      end

      it "allows symbol-key access" do
        expect(instance.props[:title]).to eq("Hello")
      end
    end

    describe "Undeclared Keys" do
      let(:instance) { test_model.new(title: "Hello", class: "foo") }

      it "preserves keys that are not declared as props" do
        expect(instance.props[:class]).to eq("foo")
      end
    end

    describe "String-Keyed Input" do
      let(:instance) { test_model.new("title" => "Hello", "count" => "42") }

      it "resolves a symbol-declared prop from string-keyed input" do
        expect(instance.props[:title]).to eq("Hello")
      end

      it "casts a symbol-declared prop from string-keyed input" do
        expect(instance.props[:count]).to eq(42)
      end
    end

    describe "String-Keyed Input with Defaults, Fallbacks, and Required" do
      let(:resolving_model) do
        Class.new do
          include ViewComponent::Props::Definable

          def self.name
            "TestComponent"
          end

          def initialize(props = {})
            setup_props_for(props)
          end
        end
      end

      context "when a default is declared" do
        before { resolving_model.class_eval { prop :title, default: "fallback" } }

        context "and a string key supplies the value" do
          let(:output) { resolving_model.new("title" => "Hello").props[:title] }

          it "uses the string-keyed value rather than the default" do
            expect(output).to eq("Hello")
          end
        end

        context "and neither key form is present" do
          let(:output) { resolving_model.new({}).props[:title] }

          it "applies the default" do
            expect(output).to eq("fallback")
          end
        end
      end

      context "when the prop is required and a string key supplies the value" do
        before { resolving_model.class_eval { prop :title, required: true } }

        let(:output) { resolving_model.new("title" => "Hello").props[:title] }

        it "resolves the string-keyed value" do
          expect(output).to eq("Hello")
        end

        it "does not raise" do
          expect { resolving_model.new("title" => "Hello") }.not_to raise_error
        end
      end
    end

    describe "Instance-Aware Callables" do
      let(:instance_aware_model) do
        Class.new do
          include ViewComponent::Props::Definable

          def self.name
            "TestComponent"
          end

          def initialize(props = {})
            setup_props_for(props)
          end

          def computed_value
            "from instance"
          end
        end
      end

      context "when a default callable references instance state" do
        before do
          instance_aware_model.class_eval { prop :title, default: -> { computed_value } }
        end

        let(:instance) { instance_aware_model.new }
        let(:output) { instance.props[:title] }

        it "returns the value from instance state" do
          expect(output).to eq("from instance")
        end
      end

      context "when a fallback callable references instance state" do
        before do
          instance_aware_model.class_eval { prop :title, fallback: -> { computed_value } }
        end

        let(:instance) { instance_aware_model.new(title: nil) }
        let(:output) { instance.props[:title] }

        it "returns the value from instance state" do
          expect(output).to eq("from instance")
        end
      end
    end
  end

  ################################################################################
  ## String-Registered Props
  ################################################################################

  describe "String-Registered Props" do
    before { test_model.class_eval { prop "title", default: "fallback" } }

    context "with symbol-keyed input" do
      let(:output) { test_model.new(title: "Hello").props[:title] }

      it "resolves the value" do
        expect(output).to eq("Hello")
      end
    end

    context "with string-keyed input" do
      let(:output) { test_model.new("title" => "Hello").props[:title] }

      it "resolves the value" do
        expect(output).to eq("Hello")
      end
    end

    context "when the key is absent" do
      let(:output) { test_model.new({}).props[:title] }

      it "applies the default" do
        expect(output).to eq("fallback")
      end
    end
  end

  ################################################################################
  ## Subclass Inheritance
  ################################################################################

  describe "Subclass Inheritance" do
    let(:parent_model) do
      Class.new do
        include ViewComponent::Props::Definable

        def self.name
          "ParentComponent"
        end

        def initialize(props = {})
          setup_props_for(props)
        end

        prop :a
      end
    end

    let!(:child_model) { Class.new(parent_model) { prop :b } }

    it "does not mutate the parent's prop_definitions when a subclass declares a prop" do
      expect(parent_model.prop_definitions.keys).to contain_exactly("a")
    end

    it "exposes both inherited and subclass props on the subclass" do
      expect(child_model.prop_definitions.keys).to contain_exactly("a", "b")
    end
  end

  ################################################################################
  ## Re-declaring a Prop
  ################################################################################

  describe "Re-declaring a Prop" do
    before do
      test_model.class_eval do
        prop :title
        prop :title, cast: :integer
      end
    end

    it "keeps a single definition for the key" do
      expect(test_model.prop_definitions.keys).to contain_exactly("title")
    end

    context "when resolving the prop" do
      let(:output) { test_model.new(title: "42").props[:title] }

      it "applies the most recent definition" do
        expect(output).to eq(42)
      end
    end
  end
end

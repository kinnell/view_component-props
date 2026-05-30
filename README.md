# ViewComponentProps

A [ViewComponent](https://viewcomponent.org) extension that adds a `prop` DSL to components: defaults, fallbacks, required props, casting, enum validation, custom validators, and a pluggable caster registry.

In Rails apps, a Railtie patches `ViewComponent::Base` during boot (enabled by default). Outside Rails, the gem patches on require. Inherit as usual and pass a props hash to `new`.

## Requirements

- Ruby >= 3.0
- [ViewComponent](https://viewcomponent.org) >= 3.0, < 5.0
- ActiveSupport >= 6.0, < 9.0
- ActiveModel >= 6.0, < 9.0

Rails is supported via a Railtie but not required; the gem auto-installs into `ViewComponent::Base` on require when Rails is not loaded.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "view_component-props"
```

And then execute:

```bash
bundle install
```

## Usage

```ruby
class ButtonComponent < ViewComponent::Base
  CLASS = %w[
    px-9
    py-3
    text-lg
    font-medium
    tracking-wider
    ring-0
  ].freeze

  prop :label, required: true
  prop :shape, cast: :symbol, enum: %i[pill rounded rectangle], default: :pill
  prop :disabled, cast: :boolean, default: false

  def before_render
    @class = cn(CLASS, {
      "rounded-full" => @props[:shape] == :pill,
      "rounded-xl" => @props[:shape] == :rounded,
      "rounded-none" => @props[:shape] == :rectangle,
    }, @props[:class])
  end

  def call
    tag.button(@props[:label], class: @class, disabled: @props[:disabled])
  end
end

render ButtonComponent.new(label: "Save", shape: :rounded)
```

Resolved props are available as `props` (or `@props`), a frozen hash you can read with either string or symbol keys. The original input, before any casting or defaults are applied, is available as `raw_props` (or `@raw_props`).

Once props are resolved, `#after_initialize` runs, so you can override it for any setup that depends on `props`.

### Options

Each `prop` accepts:

| Option         | Purpose                                                          |
| -------------- | ---------------------------------------------------------------- |
| `default:`     | Value (or callable) used when the key is missing from the input. |
| `fallback:`    | Value (or callable) used when the resolved value is `nil`.       |
| `required:`    | Raises `RequiredPropError` when the resolved value is `nil`.     |
| `cast:`        | Coerces the value. A built-in caster name or any callable.       |
| `enum:`        | Restricts the value to a list of allowed values.                 |
| `validate:`    | Callable that must return truthy for the value to be accepted.   |
| `description:` | Free-form string for documentation and tooling.                  |

Defaults and fallbacks can also be callables, evaluated in the context of the component instance. Use `raw_props` to read other props from the constructor input:

```ruby
class AvatarComponent < ViewComponent::Base
  prop :user, required: true
  prop :alt, default: -> { "#{raw_props[:user].name}'s avatar" }
end
```

### Casters

Built-in casters:

| Cast         | Coerces to                  | Notes                                                                       |
| ------------ | --------------------------- | --------------------------------------------------------------------------- |
| `:integer`   | `Integer`                   | Via `Integer(value)`; raises `CastError` on non-numeric input.              |
| `:float`     | `Float`                     | Via `Float(value)`; raises `CastError` on non-numeric input.                |
| `:string`    | `String`                    | Via `value.to_s`.                                                           |
| `:symbol`    | `Symbol`                    | Via `value.to_sym`.                                                         |
| `:boolean`   | `true` / `false`            | Uses `ActiveModel::Type::Boolean`, so `"0"`, `"false"`, `""` become `false`. |
| `:array`     | `Array`                     | Via `Array(value)`, wrapping scalars in a one-element array.                |
| `:hash`      | `Hash`                      | Returns hashes unchanged; otherwise calls `value.to_h`.                      |
| `:decimal`   | `BigDecimal`                | Returns `BigDecimal` values unchanged; otherwise `BigDecimal(value.to_s)`.   |
| `:date`      | `Date`                      | Returns `Date` values unchanged; otherwise `Date.parse(value.to_s)`.         |
| `:datetime`  | `Time` / `ActiveSupport::TimeWithZone` | Returns `Time`/`DateTime` unchanged; otherwise parses via `Time.zone` (or `Time.parse` when no zone). |

#### Nil handling

A `nil` value is **never** passed to a caster — casting is short-circuited before the caster runs, so `nil` stays `nil`. This means casters don't need to be nil-safe, and a `nil` prop is never coerced into a placeholder like `""`, `0`, or `false`. Resolution order is:

1. The key's value (or `default:` when the key is missing) is resolved.
2. If that value is `nil` and a `fallback:` is defined, the fallback is resolved.
3. Only a non-`nil` result is handed to the caster; a `nil` result passes through untouched (then triggers `required:` if set).

Use `default:` or `fallback:` when you need a concrete value for a missing or `nil` prop. Note that fallbacks are resolved *before* casting, so a `fallback:` value is cast like any other value.

Register custom casters in the configuration block:

```ruby
ViewComponentProps.configure do |config|
  config.register_caster(:slug) do |value|
    value.to_s.parameterize
  end
end

class HeadingComponent < ViewComponent::Base
  prop :anchor, cast: :slug
end
```

Built-in casters can be overridden the same way by registering the same key again in `configure`.

Or pass a lambda inline:

```ruby
prop :code, cast: ->(value) { value.to_s.upcase }
```

### Strict props

```ruby
class FormFieldComponent < ViewComponent::Base
  reject_undefined_props!

  prop :name, required: true
  prop :label
end

FormFieldComponent.new(name: "email", typo: true)
# => raises ViewComponentProps::UnknownPropsError
```

### Custom base classes

`ViewComponentProps.install!(MyComponentBase)` applies the same patch to another class (idempotent). Useful if your app uses a shared component superclass that does **not** inherit from `ViewComponent::Base`.

`install!` no-ops when the target already includes `Definable` through any ancestor, so calling it on a subclass of `ViewComponent::Base` does nothing (the patch is already inherited). You only need it for base classes outside the `ViewComponent::Base` hierarchy.

## Configuration

### Rails

Disable auto-install in `config/application.rb`:

```ruby
config.view_component_props.auto_include = false
```

When enabled (the default), `ViewComponent::Base` is patched after initializers load so `config/initializers` can configure the gem first.

### Initializer

```ruby
ViewComponentProps.configure do |config|
  config.reject_undefined_props = true

  config.register_caster(:slug) do |value|
    value.to_s.parameterize
  end
end
```

When `reject_undefined_props` is `true`, every component rejects unknown prop keys by default. Override per class with `reject_undefined_props!` or `permit_undefined_props!`.

### Non-Rails

Auto-install runs on require when `configuration.auto_include` is `true` (the default). Because it is read at require time, you must configure it **before** requiring the gem for it to have any effect:

```ruby
require "view_component_props/configuration"
ViewComponentProps.configure { |config| config.auto_include = false }

require "view_component_props"
ViewComponentProps.install!
```

Configuring `auto_include` _after_ `require "view_component_props"` cannot reverse the install that already happened. Note this `configuration.auto_include` switch is consulted only outside Rails; in Rails the equivalent switch is `config.view_component_props.auto_include`, handled by the Railtie.

## Development

After checking out the repo, run:

```bash
bin/setup
```

Run the test suite:

```bash
bundle exec rspec
```

Run the linter:

```bash
bundle exec rubocop
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kinnell/view_component-props.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

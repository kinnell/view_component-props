# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [X.X.X] - YYYY-MM-DD

## [0.0.1] - 2026-05-20

### Added

- `prop` DSL with `default`, `fallback`, `required`, `cast`, `enum`, `validate`, and `description` options
- Resolved `props` (frozen indifferent hash) and `raw_props` on each instance; `prop_definitions` on the component class for introspection
- Built-in casters: `:integer`, `:float`, `:string`, `:symbol`, `:boolean`, `:array`, `:hash`, `:decimal`, `:date`, `:datetime`
- `ViewComponent::Props.configure` for global settings and `register_caster` for custom or overriding casters
- Auto-install into `ViewComponent::Base` (Rails Railtie after initializers, or on require outside Rails); `#initialize` accepts a props hash and invokes `#after_initialize` after resolution
- Global `reject_undefined_props` configuration and per-class `reject_undefined_props!` / `permit_undefined_props!`
- `ViewComponent::Props.install!` for patching additional base classes outside `ViewComponent::Base`
- Typed errors under `ViewComponent::Props::Error` (`UnknownOptionError`, `UnknownCastError`, `CastError`, `RequiredPropError`, `InvalidEnumValueError`, `ValidationFailedError`, `UnknownPropsError`)

## [0.0.0] - 2026-05-20

- Initial repository scaffolding and gem publication. No functionality yet.

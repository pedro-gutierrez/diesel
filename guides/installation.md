# Installation

The package can be installed by adding `diesel` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:diesel, "~> 0.7"}
  ]
end
```

# Formatter setup

In order to avoid superfluous parenthesis when defining structured tags in your DSL, also add `diesel` to your dependencies in your `.formatter.exs`:

```elixir
[
  inputs: [ ... ],
  import_deps: [..., :diesel],
  locals_without_parens: ...,
]
```

# Extensibility

## Packages

Packages are a way to extend existing dsl with new groups of tags. Rather than inlining the list of
tags offered by a DSL, we can express it a list of packages:

```elixir
defmodule MyApp.Fsm.Dsl do
  use Diesel.Dsl,
    otp_app: :my_app,
    root: MyApp.Fsm.Dsl.Fsm,
    packages: [
      MyApp.Fsm.Dsl.Basic
    ]
end
```

with:

```elixir
defmodule MyApp.Fsm.Dsl.Basic do
  use Diesel.Package, tags: [
    MyApp.Fsm.Dsl.Action,
    MyApp.Fsm.Dsl.Next,
    MyApp.Fsm.Dsl.On,
    MyApp.Fsm.Dsl.State
  ]
end
```

## Extending existing DSLs

DSLs made with Diesel are not closed. Once defined, they can still be extended by application
developers, via application environment configuration:

```elixir
config :my_app, MyApp.Fsm.Dsl, packages: [ ...]
```

## Generating more code

Similarly to DSLs, library modules can be enriched with extra generated code via application
environment configuration:

```elixir
config :my_app, MyApp.Fsm, generators: [ ... ]
```

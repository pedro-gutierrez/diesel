# Diesel

A toolkit to build DSLs in Elixir

## Installation

The package can be installed by adding `diesel` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:diesel, "~> 0.1.0"}
  ]
end
```
## Description

DSLs built with Diesel are:

* Purely declarative: they look just like HTML
* Extensible: via block modules and generators

## Usage

### Defining a DSL

A new DSL can be defined with:

```elixir
defmodule FsmDsl do
  use Diesel.Dsl,
    otp_app: :my_app,
    root: :fsm,
    blocks: [
      FsmDsl.State
    ]
end
```

with:

```elixir
defmodule FsmDsl.State do
  use Diesel.Block, tags: [:state]
end
```

### Compiling a DSL

Once defined, a DSL syntax can be used by another library module:

```elixir
defmodule Fsm do
  use Diesel,
    otp_app: :my_app,
    dsl: FsmDsl,
    generators: [ ... ]
end
```

A list of generator mode can be provided, in order to produce actual Elixir code out of the DSL.
Check the `Diesel.Generator` behaviour for more information on this.

### Using a DSL

The `Fsm` library module from the example above is now ready to be used:

```elixir
defmodule Payment do
  use Fsm

  fsm do
    state name: :pending do
      ...
    end

    state name: :accepted do
      ...
    end

    state name: :declined do
      ...
    end
  end
end
```

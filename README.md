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
* Extensible: via block modules

## Usage

### Defining a DSL

A new DSL can be defined with:

```elixir
defmodule FsmDsl do
  use Diesel,
    name: :fsm,
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

Once defined, a DSL can be used by another library module, by calling its `definition`
function, in order to transform it into actual Elixir code, right before compilation:

```elixir
defmodule Fsm do

  defmacro __using__(_opts) do
    quote do
      import FsmDsl
      @before_compile Fsm
    end
  end

  defmacro __before_compile_(env) do
    def = definition()

    quote do
      ...
    end
  end
end
```

### Using a DSL

For example, With the `Fsm` library module from the example above, we could write:

```elixir
defmodule Payment do
  use Fsm

  fsm do
    state name: :accepted do
      ...
    end

    state name: :declined do
      ...
    end
  end
end
```

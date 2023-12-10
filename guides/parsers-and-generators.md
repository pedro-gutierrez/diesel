# Parsers and generators

## Raw definitions

By default, DSLs generated with Diesel are compiled into a tree-like structure of nodes as tuples.

This is similar to the structure you'd expect from a HTML document parsed with Loki. For example,
the following code:

```elixir
defmodule MyApp.Fsm.Paymnent do
  use MyApp.Fsm

  fsm do
    state :pending do
    end
  end
end
```

gives the following internal raw definition:

```elixir
{:fsm, [], [
  {:state, [name: :pending], []}
]}
```

By default, this is the datastructure that will be then consumed by code generators.

## The parser behaviour

It is possible however to add parsing steps and convert the raw definition into a more suitable data
structure, before it is consumed by generators.

All you need to do is implement the `Diesel.Parser` behaviour in a new elixir module:

```elixir
defmodule MyApp.Fsm.MyParser do
  @moduledoc "Converts a fsm definition into structs"
  @behaviour Diesel.Parser

  @impl true
  def parse(caller, {:fsm, [], states}) do
    %Fsm{states: [...]}
  end
end
```

and add it to the list of parsers:

```elixir
defmodule MyApp.Fsm do
  use Diesel,
    otp_app: ...,
    dsl: ...,
    parsers: [
      MyApp.Fsm.MyParser
    ]

  defstruct states: []
end
```

The `Diesel` module provides with several convenience functions to traverse definitions:

* `children/2`: returns all children elements with the given tag name
* `nodes/2`: returns all elements in the given list with the given tag name
* `child/2`: returns the first child with the given tag name
* `child/1`: returns the first child of the given element or list of elements

## Generating code

By implementing the `Diesel.Generator` behaviour, developers can produce elixir code, based on a DSL
definition. For example, we could imagine a GenServer based implementation of a state machine:

```elixir
defmodule MyApp.Fsm do
  use Diesel,
    otp_app: ...,
    dsl: ...,
    parsers: [...],
    generators: [
      MyApp.Fsm.Generator.GenServer
    ]
```

where:

```elixir
defmodule MyApp.Fsm.Generator.GenServer do
  @moduledoc "Generates a GenServer for a state machine DSL"
  @behaviour Diesel.Generator

  @impl true
  def generate(caller, definition) do
    quote do
      use GenServer
      ...
    end
  end
end
```

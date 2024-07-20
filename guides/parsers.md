# Parsers

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

## The Parser behaviour

It is possible however to add parsing steps and convert the raw definition into a more suitable data
structure, before it is consumed by generators.

All you need to do is implement the `Diesel.Parser` behaviour in a new elixir module:

```elixir
defmodule MyApp.Fsm.MyParser do
  @moduledoc "Converts a fsm definition into structs"
  @behaviour Diesel.Parser

  @impl true
  def parse({:fsm, [], states}, _opts) do
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

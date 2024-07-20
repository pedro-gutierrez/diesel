# Generators

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
  def generate(definition, _opts) do
    quote do
      use GenServer
      ...
    end
  end
end
```

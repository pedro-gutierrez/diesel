defmodule Diesel.Parser do
  @moduledoc """
  Parses a raw dsl definition before compilation

  Example:

  ```elixir
  def parse(caller_module, {:music, attrs, children}) do
    # eg return some struct here
  end
  ```

  Parsing a definition is an optional step. The result returned will be then passed to generators.

  Modules using the `Diesel` are given a default, though overriable, no-op implementation
  """
  @callback parse(caller_module :: module(), definition :: term()) :: term()
end

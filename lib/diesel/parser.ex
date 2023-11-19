defmodule Diesel.Parser do
  @moduledoc """
  A parser is a DSL tranformation step before code generation

  Example:

  ```elixir
  def parse(caller_module, {:music, attrs, children}) do
    # eg return some struct here
  end
  ```

  Parsing a definition is an optional step.
  """
  @callback parse(caller_module :: module(), definition :: term()) :: term()

  @doc """
  Returns a built-in parser, given its name

  Supported names:

  * `strip_root`
  """
  def named(:strip_root), do: Diesel.Parser.StripRoot
  def named(other), do: raise("No built-in parser for name #{inspect(other)}")
end

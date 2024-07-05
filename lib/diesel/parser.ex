defmodule Diesel.Parser do
  @moduledoc """
  A parser is a DSL tranformation step before code generation

  Example:

  ```elixir
  def parse({:music, attrs, children}, _opts) do
    # eg return some struct here
  end
  ```

  Parsing a definition is an optional step.
  """
  @callback parse(definition :: term(), opts :: keyword()) :: term()

  @doc """
  Returns a built-in parser, given its name

  Supported names:

  * `strip_root`
  """
  def named(:strip_root), do: Diesel.Parser.StripRoot
  def named(other), do: raise("No built-in parser for name #{inspect(other)}")
end

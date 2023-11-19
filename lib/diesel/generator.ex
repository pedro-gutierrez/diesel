defmodule Diesel.Generator do
  @moduledoc """
  Generators produce actual Elixir code from DSLs.

  Given a caller module and a dsl definition, a generator returns one or multiple quoted expressions.
  """
  @callback generate(target :: module(), definition :: term()) :: Macro.t() | [Macro.t()]
end

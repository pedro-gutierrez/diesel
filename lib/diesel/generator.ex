defmodule Diesel.Generator do
  @moduledoc """
  Generators produce Elixir code based on DSLs, before modules are compiled.
  """
  @callback generate(target :: module(), definition :: term()) :: Macro.t() | [Macro.t()]
end

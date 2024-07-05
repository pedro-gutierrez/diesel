defmodule Diesel.Parser.StripRoot do
  @moduledoc """
  A built-in DSL parser that removes the root tag from a definition

  This parser is activated when the `:strip_root` compilation flag is enabled
  """
  @behaviour Diesel.Parser

  @impl true
  def parse(definition, _opts), do: strip_root(definition)

  defp strip_root({_, _, [child]}), do: child
  defp strip_root({_, _, children}), do: children
end

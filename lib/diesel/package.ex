defmodule Diesel.Package do
  @moduledoc """
  Packages extend DSLs by defining new tags.

  Usage:

  ```elixir
  defmodule Latex.Dsl.Music do
    use Diesel.Package,
      tags: [
        :music,
        :instrument,
        :meter
      ]
  end
  ```
  """

  @callback tags() :: [atom()]
  @callback compiler() :: Macro.t()
  @optional_callbacks compiler: 0

  defmacro __using__(opts) do
    tags = Keyword.fetch!(opts, :tags)

    quote do
      @behaviour Diesel.Package

      @impl Diesel.Package
      def tags, do: unquote(tags)
    end
  end
end

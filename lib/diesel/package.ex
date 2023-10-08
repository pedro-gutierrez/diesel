defmodule Diesel.Package do
  @moduledoc """
  A package contributes to a DSL with a set of tags.

  Optionally, packages can also specify how these tags should be compiled, in order to form a new definition that can then be consumed by generators

  Usage:

  ```elixir
  defmodule MyApp.MyDsl.Style do
    use Diesel.Package,
      tags: [:style]

    @impl Diesel.Package
    def compiler do
      quote do
        def compile({:style, attrs, children}, ctx) do
          ...
        end
      end
    end
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

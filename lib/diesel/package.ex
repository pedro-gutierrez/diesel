defmodule Diesel.Package do
  @moduledoc """
  Packages extend DSLs by providing new tags.

  Optionally, packages can also specify how these tags should be compiled, in order to form a new definition that can then be consumed by code generators.

  Usage:

  ```elixir
  defmodule Latex.Dsl.Music do
    use Diesel.Package,
      tags: [
        :music,
        :instrument,
        :meter
      ]

    @impl true
    def compiler do
      quote do
        def compile({:music, attrs, children}, ctx) do
          atttrs = Keyword.put_new(attrs, :indent, "10mm")
          children = compile(children, ctx)

          {:music, attrs, children}
        end
      end
    end
  end
  ```

  The code returned by each package via the `compiler/1` function will be injected into the Dsl.

  The `Diesel.Dsl` macro provides with a default implementation for the `compile/2` callback, so that you can conveniently traverse the definition tree.
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

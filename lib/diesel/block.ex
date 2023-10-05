defmodule Diesel.Package do
  @moduledoc """
  A building package of a DSL.

  Usage:

  ```elixir
  defmodule MyApp.MyDsl.Style do
    use Diesel.Package,
      tags: [:style]

    def resolve({:style, _, _}, ctx), do: ...
  end
  ```
  """

  defmacro __using__(opts) do
    tags = Keyword.fetch!(opts, :tags)

    quote do
      @before_compile Diesel.Package

      def tags, do: unquote(tags)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def resolve({tag, _, _}, _) do
        {:error, :tag_unsupported, tag}
      end
    end
  end
end

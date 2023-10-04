defmodule Diesel.Block do
  @moduledoc """
  A building block of a DSL.

  Usage:

  ```elixir
  defmodule MyApp.MyDsl.Style do
    use Diesel.Block,
      tags: [:style]

    @impl Diesel.Block
    def resolve({:style, _, _}, ctx), do: ...
  end
  ```
  """
  @callback tags() :: [Diesel.tag()]
  @callback resolve(el :: Diesel.element(), context :: map()) :: any()

  defmacro __using__(opts) do
    tags = Keyword.fetch!(opts, :tags)

    quote do
      @before_compile Diesel.Block
      @behaviour Diesel.Block

      @impl Diesel.Block
      def tags, do: unquote(tags)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl Diesel.Block
      def resolve({tag, _, _}, _) do
        {:error, :tag_unsupported, tag}
      end
    end
  end
end

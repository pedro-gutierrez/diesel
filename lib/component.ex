defmodule Diesel.Component do
  @moduledoc """
  A DSL component extends a DSL

  Usage:

  ```elixir
  defmodule MyApp.MyDsl.Base do
    use Diesel.Component,
      tags: [:style]

    @impl Diesel.Component
    def resolve({:style, _, _}, ctx), do: ...
  end
  ```
  """
  @type dsl_tag() :: atom()
  @type dsl_attrs() :: keyword() | binary() | module()
  @type dsl_node() :: {dsl_tag(), dsl_attrs(), [dsl_node()]}
  @callback tags() :: [dsl_tag()]
  @callback resolve(node :: dsl_node(), context :: map()) :: any()

  defmacro __using__(opts) do
    tags = Keyword.fetch!(opts, :tags)

    quote do
      @before_compile Diesel.Component
      @behaviour Diesel.Component

      @impl Diesel.Component
      def tags, do: unquote(tags)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def resolve({tag, _, _}, _) do
        raise Diesel.TagNotSupported, "tag :#{tag} is not supported"
      end
    end
  end
end

defmodule Diesel do
  @moduledoc """
  Elixir DSL builder toolkit.

  DSLs built with this library are actually documents. They look like HTML, and can be extended via components.

  Usage:

  ```elixir
  defmodule MyApp.MyDsl do
    use Diesel,
      otp_app: :my_app,
      name: :style,
      components: [
        MyApp.MyDsl.OneComponent,
        MyApp.MyDsl.AnotherComponent,
      ]
  end
  ```
  Additional components can be specified via application environment. These will be merged with the
  list of components already declared in the module:

  ```elixir
  config :my_app, MyApp.MyDsl,
    components: [
      OtherApp.AThirdComponent
    ]
  ```
  """

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    name = Keyword.fetch!(opts, :name)

    default_components =
      opts
      |> Keyword.fetch!(:components)
      |> Enum.map(fn {_, _, parts} ->
        Module.concat(parts)
      end)

    extra_components =
      otp_app |> Application.get_env(__MODULE__, []) |> Keyword.get(:components, [])

    components = default_components ++ extra_components
    tags = Enum.flat_map(components, & &1.tags)

    quote do
      @name unquote(name)
      @components unquote(components)
      @tags unquote(tags)
      @before_compile Diesel

      @doc false
      def tags, do: @tags

      @doc false
      def name, do: @name

      @doc false
      def components, do: @components

      @doc false
      def locals_without_parens do
        for tag <- @tags, do: {tag, :*}
      end

      @doc false
      def resolve(node, args) do
        Enum.reduce_while(@components, :not_supported, fn component, _ ->
          case component.resolve(node, args) do
            :not_supported -> {:cont, :not_supported}
            other -> {:halt, other}
          end
        end)
      end
    end
  end

  defmacro __before_compile__(_env) do
    dsl = __CALLER__.module

    [root_macros(dsl) | tags_macros(dsl)]
  end

  defp root_macros(dsl) do
    name = Module.get_attribute(dsl, :name)

    quote do
      defmacro unquote(name)(do: {:__block__, [], children}) do
        quote do
          @doc false
          def definition, do: unquote(children)
        end
      end

      defmacro unquote(name)(do: child) do
        quote do
          @doc false
          def definition, do: unquote([child])
        end
      end
    end
  end

  defp tags_macros(dsl) do
    dsl
    |> Module.get_attribute(:tags)
    |> Enum.map(&tag_macros/1)
  end

  defp tag_macros(tag) do
    quote do
      defmacro unquote(tag)(attrs, do: {:__block__, _, children}) do
        {:{}, [line: 1], [unquote(tag), attrs, children]}
      end

      defmacro unquote(tag)(attrs, do: child) do
        {:{}, [line: 1], [unquote(tag), attrs, [child]]}
      end

      defmacro unquote(tag)(do: {:__block__, _, children}) do
        {:{}, [line: 1], [unquote(tag), [], children]}
      end

      defmacro unquote(tag)(do: child) do
        {:{}, [line: 1], [unquote(tag), [], [child]]}
      end

      defmacro unquote(tag)(attrs) when is_list(attrs) do
        {:{}, [line: 1], [unquote(tag), attrs, []]}
      end

      defmacro unquote(tag)(child) when is_binary(child) do
        {:{}, [line: 1], [unquote(tag), [], [child]]}
      end

      defmacro unquote(tag)() do
        {:{}, [line: 1], [unquote(tag), [], []]}
      end
    end
  end
end

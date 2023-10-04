defmodule Diesel do
  @moduledoc """
  Elixir DSL builder toolkit.

  DSLs built with this library are actually documents. They look like HTML, and can be extended via blocks.

  Usage:

  ```elixir
  defmodule MyApp.MyDsl do
    use Diesel,
      otp_app: :my_app,
      root: :style,
      blocks: [
        MyApp.MyDsl.OneBlock,
        MyApp.MyDsl.AnotherBlock,
      ]
  end
  ```
  Additional blocks can be specified via application environment. These will be merged with the
  list of blocks already declared in the module:

  ```elixir
  config :my_app, MyApp.MyDsl,
    blocks: [
      OtherApp.AThirdBlock
    ]
  ```
  """

  @type tag() :: atom()
  @type opts() :: keyword() | atom() | module() | binary()
  @type element() :: {tag(), opts(), [element()]}

  @doc "The tags supported by the dsl"
  @callback tags() :: [tag()]

  @doc "The blocks that contribute to the definition of the dsl"
  @callback blocks() :: [module()]

  @doc "The root tag of the dsl"
  @callback root() :: tag()

  @doc "Formatter configuration"
  @callback locals_without_parens() :: keyword()

  @doc "Resolves an element into something else, given a context"
  @callback resolve(element :: element(), context :: map()) :: any()

  defmacro(__using__(opts)) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    root = Keyword.fetch!(opts, :root)

    default_blocks =
      opts
      |> Keyword.fetch!(:blocks)
      |> Enum.map(fn {_, _, parts} ->
        Module.concat(parts)
      end)

    extra_blocks =
      otp_app
      |> Application.get_env(__CALLER__.module, [])
      |> Keyword.get(:blocks, [])

    blocks = default_blocks ++ extra_blocks
    tags = Enum.flat_map(blocks, & &1.tags)

    quote do
      @root unquote(root)
      @blocks unquote(blocks)
      @tags unquote(tags)
      @behaviour Diesel

      @impl true
      def tags, do: @tags

      @impl true
      def root, do: @root

      @impl true
      def blocks, do: @blocks

      @impl true
      def locals_without_parens do
        for tag <- @tags, do: {tag, :*}
      end

      defmacro unquote(root)(do: {:__block__, [], children}) do
        quote do
          def definition, do: unquote(children)
        end
      end

      defmacro unquote(root)(do: child) do
        quote do
          def definition, do: unquote([child])
        end
      end

      unquote_splicing(
        Enum.map(tags, fn tag ->
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

            defmacro unquote(tag)(child) do
              {:{}, [line: 1], [unquote(tag), [], [child]]}
            end

            defmacro unquote(tag)() do
              {:{}, [line: 1], [unquote(tag), [], []]}
            end
          end
        end)
      )

      @impl true
      def resolve(el, args) do
        Enum.reduce_while(@blocks, nil, fn block, _ ->
          case block.resolve(el, args) do
            {:error, :tag_unsupported, _} = error -> {:cont, error}
            other -> {:halt, other}
          end
        end)
      end
    end
  end
end

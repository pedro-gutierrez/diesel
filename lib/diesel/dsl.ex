defmodule Diesel.Dsl do
  @moduledoc """
  Elixir DSL builder toolkit.

  DSLs built with this library are actually documents. They look like HTML, and can be extended via packages.

  Usage:

  ```elixir
  defmodule MyApp.MyDsl do
    use Diesel.Dsl,
      otp_app: :my_app,
      root: :style,
      packages: [
        MyApp.MyDsl.Package1,
        MyApp.MyDsl.Package2,
      ]
  end
  ```
  Additional packages can be specified via application environment. These will be appended to the
  list of packages already declared in the module:

  ```elixir
  config :my_app, MyApp.MyDsl,
    packages: [
      OtherApp.SomeExtension
    ]
  ```
  """

  defmacro(__using__(opts)) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    root = Keyword.fetch!(opts, :root)

    default_packages =
      opts
      |> Keyword.fetch!(:packages)
      |> Enum.map(fn {_, _, parts} ->
        Module.concat(parts)
      end)

    extra_packages =
      otp_app
      |> Application.get_env(__CALLER__.module, [])
      |> Keyword.get(:packages, [])

    packages = default_packages ++ extra_packages
    tags = Enum.flat_map(packages, & &1.tags)

    quote do
      @root unquote(root)
      @packages unquote(packages)
      @tags unquote(tags)

      def tags, do: @tags
      def root, do: @root
      def packages, do: @packages

      def locals_without_parens do
        for tag <- @tags, do: {tag, :*}
      end

      defmacro unquote(root)(do: {:__block__, [], children}) do
        quote do
          @definition unquote(children)
          def definition, do: @definition
        end
      end

      defmacro unquote(root)(do: child) do
        quote do
          @definition unquote(child)
          def definition, do: @definition
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

      def resolve(el, args) do
        Enum.reduce_while(@packages, nil, fn p, _ ->
          case p.resolve(el, args) do
            {:error, :tag_unsupported, _} = error -> {:cont, error}
            other -> {:halt, other}
          end
        end)
      end
    end
  end
end

defmodule Diesel.Dsl do
  @moduledoc """
  Elixir DSL builder toolkit.

  DSLs built with this library are actually documents. They look like HTML, and can be extended via packages.

  Simple usage:

  ```elixir
  defmodule MyApp.Latex do
    use Diesel.Dsl,
      otp_app: :my_app,
      root: :latex,
      tags: [
        :document,
        :package,
        :section,
        :subsection
      ]
  end
  ```

  A DSL can be extended via packages:

  ```elixir
  defmodule MyApp.Latex do
    use Diesel.Dsl,
      ...
      packages: [
        MyApp.Latex.Music,
      ]
  end
  ```

  Additional packages can be specified via application environment. These will be appended to the
  list of packages already declared in the module:

  ```elixir
  config :my_app, MyApp.Latex,
    packages: [
      OtherApp.Latex.Math
    ]
  ```
  """

  defmacro(__using__(opts)) do
    dsl = __CALLER__.module
    otp_app = Keyword.fetch!(opts, :otp_app)
    root = Keyword.fetch!(opts, :root)
    default_tags = Keyword.get(opts, :tags, [])

    default_packages =
      opts
      |> Keyword.get(:packages, [])
      |> Enum.map(fn {_, _, parts} -> Module.concat(parts) end)

    extra_packages =
      otp_app
      |> Application.get_env(__CALLER__.module, [])
      |> Keyword.get(:packages, [])

    packages = default_packages ++ extra_packages
    tags = default_tags ++ Enum.flat_map(packages, & &1.tags)

    if Enum.empty?(tags), do: "No tags defined in #{inspect(dsl)}"

    tags = Enum.uniq(tags)

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

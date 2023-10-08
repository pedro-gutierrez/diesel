defmodule Diesel.Dsl do
  @moduledoc """
  Defines the syntax provided by a DSL.

  DSLs built with Diesel:

  * are documents. They look like HTML.
  * define tags
  * can be compiled
  * can be extended via packages and code generators

  Simple usage:

  ```elixir
  defmodule Latex.Dsl do
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
  defmodule Latex.Dsl do
    use Diesel.Dsl,
      ...
      packages: [
        Latex.Dsl.Music
      ]
  end
  ```

  Packages allow you to define extra tags, as well as compiler rules.

  Additional packages can be specified via application environment.

  These will be appended to the list of packages already declared in the module:

  ```elixir
  config :latex, Latex.Dsl,
    packages: [
      OtherApp.Latex.Dsl.Math
    ]
  ```
  """

  @callback tags() :: [atom()]
  @callback root() :: atom()
  @callback locals_without_parens() :: keyword()
  @callback compile(node :: tuple(), ctx :: map()) :: tuple()

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
      @behaviour Diesel.Dsl
      @before_compile Diesel.Dsl
      @root unquote(root)
      @packages unquote(packages)
      @tags unquote(tags)

      @impl Diesel.Dsl
      def tags, do: @tags

      @impl Diesel.Dsl
      def root, do: @root

      @impl Diesel.Dsl
      def locals_without_parens do
        for tag <- @tags, do: {tag, :*}
      end

      defmacro unquote(root)(do: {:__block__, [], children}) do
        quote do
          @definition unquote(children)

          @impl Diesel
          def definition, do: @definition
        end
      end

      defmacro unquote(root)(do: child) do
        quote do
          @definition unquote(child)

          @impl Diesel
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
    end
  end

  defmacro __before_compile__(_env) do
    package_compilers =
      __CALLER__.module
      |> Module.get_attribute(:packages)
      |> Enum.filter(&function_exported?(&1, :compiler, 0))
      |> Enum.map(& &1.compiler())

    default_compiler =
      quote do
        @impl Diesel.Dsl
        def compile({tag, attrs, children}, ctx) do
          {tag, compile(attrs, ctx), compile(children, ctx)}
        end

        def compile(elements, ctx) when is_list(elements) do
          elements
          |> Enum.map(&[compile(&1, ctx)])
          |> List.flatten()
        end

        def compile({attr_name, attr_value}, ctx) when is_atom(attr_name) do
          {attr_name, compile(attr_value, ctx)}
        end

        def compile(str, ctx) when is_binary(str) do
          Diesel.Templating.render!(str, ctx)
        end

        def compile(x, _ctx), do: x
      end

    package_compilers ++ [default_compiler]
  end
end

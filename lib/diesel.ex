defmodule Diesel do
  @moduledoc """
  Declarative programming in Elixir

  Diesel is a toolkit that helps you build your own DSLs.

  Example:

  ```elixir
  defmodule Latex.Dsl do
    use Diesel.Dsl,
      otp_app: :latex,
      root: :latex,
      packages: [...],
      tags: [
        :document,
        :package,
        :packages,
        :section,
        :subsection,
        ...
      ],
  end

  defmodule Latex.Pdf do
    @behaviour Diesel.Generator

    @impl true
    def generate(_mod, definition) do
      quote do
        def to_pdf, do: "%PDF-1.4 ..."
      end
    end
  end

  defmodule Latex do
    use Diesel,
      otp_app: :my_app,
      dsl: Latex.Dsl,
      generators: [
        Latex.Pdf
      ]
  end
  ```

  then we could use it with:

  ```elixir
  defmodule MyApp.Paper do
    use Latex

    latex do
      document size: "a4" do
        packages [:babel, :graphics]

        section title: "Introduction" do
          subsection title: "Details" do
            ...
          end
        end
      end
    end
  end

  iex> MyApp.Paper.to_pdf()
  "%PDF-1.4 ..."
  ```

  DSLs built with Diesel are not sealed: they can be easily extended both with packages and code generators. These can be even defined by other apps, via application environment:

  ```elixir
  config :latex, Latex.Dsl, packages: [ ...]
  config :my_app, MyApp.Paper, generators: [...]
  ```

  Please take a look at the `Diesel.Dsl` module documentation and also the examples provided in tests.
  """
  @type tag() :: atom()
  @type attrs() :: keyword()
  @type element() :: {tag(), attrs(), [element()]}

  @callback definition() :: element()
  @callback compile(ctx :: map()) :: any()

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    mod = __CALLER__.module
    dsl = Keyword.fetch!(opts, :dsl)
    overrides = Keyword.get(opts, :overrides, [])
    compilation_flags = Keyword.get(opts, :compilation_flags, [])

    generators =
      Keyword.get(opts, :generators, []) ++
        (otp_app
         |> Application.get_env(mod, [])
         |> Keyword.get(:generators, []))

    quote do
      @dsl unquote(dsl)
      @overrides unquote(overrides)
      @mod unquote(mod)
      @generators unquote(generators)
      @compilation_flags unquote(compilation_flags)

      defmacro __using__(_) do
        mod = __CALLER__.module

        quote do
          @behaviour Diesel

          @dsl unquote(@dsl)
          @root @dsl.root()
          import Kernel, except: unquote(@overrides)
          import unquote(@dsl), only: :macros
          @before_compile unquote(@mod)

          @impl Diesel
          def compile(ctx \\ %{}) do
            definition() |> maybe_strip_root() |> @dsl.compile(ctx)
          end

          if unquote(Enum.member?(@compilation_flags, :strip_root)) do
            defp maybe_strip_root({@root, _, [child]}), do: child
            defp maybe_strip_root({@root, _, children}), do: children
          else
            defp maybe_strip_root(definition), do: definition
          end
        end
      end

      defmacro __before_compile__(_env) do
        mod = __CALLER__.module
        definition = Module.get_attribute(mod, :definition)

        [definition_ast()] ++
          Enum.flat_map(@generators, &[&1.generate(mod, definition)])
      end

      defp definition_ast do
        quote do
          @impl Diesel
          def definition, do: @definition
        end
      end
    end
  end
end

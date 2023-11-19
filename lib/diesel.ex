defmodule Diesel do
  @moduledoc """
  Declarative programming in Elixir

  Diesel is a toolkit that helps you build your own DSLs.

  Usage:

  ```elixir
  defmodule MyApp.Fsm do
    use Diesel,
      otp_app: :my_app,
      dsl: MyApp.Fsm.Dsl,
      parsers: [
        ...
      ],
      generators: [
        ...
      ]
  end
  ```

  For more information on how to use this library, please check:

  * the `Diesel.Dsl` and `Diesel.Tag` modules,
  * the guides and tutorials provided in the documentation
  * the examples used in tests
  """

  @doc "Returns the raw definition for the dsl, before compilation"
  @callback definition() :: term()

  @doc """
  Compiles the raw definition and returns a compiled version of it

  The obtained structure is the result of applying the configured list of parsers to the raw
  internal definition and then compiling it according to the rules implemented by packages.
  """
  @callback compile(context :: map()) :: term()

  alias Diesel.Parser
  import Diesel.Naming

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    mod = __CALLER__.module
    dsl = opts |> Keyword.fetch!(:dsl) |> module_name()
    overrides = Keyword.get(opts, :overrides, [])
    compilation_flags = Keyword.get(opts, :compilation_flags, [])

    generators =
      Keyword.get(opts, :generators, []) ++
        (otp_app
         |> Application.get_env(mod, [])
         |> Keyword.get(:generators, []))

    generators = Enum.map(generators, &module_name/1)

    parsers =
      Keyword.get(opts, :parsers, []) ++
        (otp_app
         |> Application.get_env(mod, [])
         |> Keyword.get(:parsers, []))

    parsers = Enum.map(compilation_flags, &Parser.named/1) ++ parsers

    parsers = Enum.map(parsers, &module_name/1)

    quote do
      @otp_app unquote(otp_app)
      @dsl unquote(dsl)
      @overrides unquote(overrides)
      @mod unquote(mod)
      @parsers unquote(parsers)
      @generators unquote(generators)

      defmacro __using__(_) do
        mod = __CALLER__.module

        quote do
          @behaviour Diesel
          @otp_app unquote(@otp_app)
          @dsl unquote(@dsl)
          @parsers unquote(@parsers)
          @generators unquote(@generators)
          @root @dsl.root()
          import Kernel, except: unquote(@overrides)
          import unquote(@dsl), only: :macros
          @before_compile unquote(@mod)

          @compilation_context @otp_app
                               |> Application.compile_env(__MODULE__, [])
                               |> Keyword.get(:compilation_context, %{})

          @impl Diesel
          def compile(ctx \\ %{}) do
            ctx = Map.merge(@compilation_context, Map.new(ctx))

            @parsers
            |> Enum.reduce(definition(), & &1.parse(__MODULE__, &2))
            |> @dsl.compile(ctx)
          end
        end
      end

      defmacro __before_compile__(_env) do
        mod = __CALLER__.module
        compilation_context = Module.get_attribute(mod, :compilation_context)
        dsl = Module.get_attribute(mod, :dsl)
        definition = Module.get_attribute(mod, :definition)
        parsers = Module.get_attribute(mod, :parsers)
        generators = Module.get_attribute(mod, :generators)

        Diesel.Dsl.validate!(dsl, definition)

        definition = Enum.reduce(parsers, definition, & &1.parse(mod, &2))

        generated_code =
          generators
          |> Enum.flat_map(&[&1.generate(mod, definition)])
          |> Enum.reject(&is_nil/1)

        [definition_ast() | generated_code]
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

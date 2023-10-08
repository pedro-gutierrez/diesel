defmodule Diesel do
  @moduledoc """
  Declarative programming in Elixir

  DSLs define the syntax, generators produce code based on that syntax.

  Sample usage:

  ```elixir
  defmodule MyApp.SomeModule do
    use Diesel,
      otp_app: :my_app,
      dsl: MyApp.SomeDsl,
      generators: [
        MyApp.SomeGenerator
      ]
  end
  ```

  DSLs built with Diesel are not closed: the can be easily extended by application developers via
  application environment configuration:

  ```elixir
  config :my_app, MyApp.Module,
    generators: [MyApp.ExtraGenerator]
  ```

  Please take a look at the `Diesel.Dsl` module documentation and also the examples provided in the
  tests.
  """
  @type tag() :: atom()
  @type attrs() :: keyword()
  @type element() :: {tag(), attrs(), [element()]}

  @callback definition() :: element() | [element()]
  @callback compile(ctx :: map()) :: element() | [element()]

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    mod = __CALLER__.module
    dsl = Keyword.fetch!(opts, :dsl)
    overrides = Keyword.get(opts, :overrides, [])

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

      defmacro __using__(_) do
        mod = __CALLER__.module

        quote do
          @behaviour Diesel

          @dsl unquote(@dsl)
          import Kernel, except: unquote(@overrides)
          import unquote(@dsl), only: :macros
          @before_compile unquote(@mod)

          @impl Diesel
          def compile(ctx \\ %{}), do: definition() |> @dsl.compile(ctx)
        end
      end

      defmacro __before_compile__(_env) do
        mod = __CALLER__.module
        definition = Module.get_attribute(mod, :definition)
        Enum.flat_map(@generators, &[&1.generate(mod, definition)])
      end
    end
  end
end

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

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    mod = __CALLER__.module
    dsl = Keyword.fetch!(opts, :dsl)
    default_generators = Keyword.get(opts, :generators, [])

    extra_generators =
      otp_app
      |> Application.get_env(mod, [])
      |> Keyword.get(:generators, [])

    IO.inspect(mod: mod, extra_generators: extra_generators)

    generators = default_generators ++ extra_generators

    quote do
      @dsl unquote(dsl)
      @mod unquote(mod)
      @generators unquote(generators)

      defmacro __using__(_) do
        mod = __CALLER__.module

        quote do
          @dsl unquote(@dsl)
          import unquote(@dsl), only: :macros
          @before_compile unquote(@mod)
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

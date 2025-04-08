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

  @type tag() :: atom()
  @type element() :: {tag(), keyword(), [element()]}

  @doc "Returns the raw definition for the dsl, before compilation"
  @callback definition() :: element()

  import Diesel.Naming

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    mod = __CALLER__.module
    default_dsl = Module.concat(mod, Dsl)
    default_parser = Module.concat(mod, Parser)

    dsl = opts |> Keyword.get(:dsl, default_dsl) |> module_name()
    overrides = Keyword.get(opts, :overrides, [])
    generators = opts |> Keyword.get(:generators, []) |> Enum.map(&module_name/1)
    parsers = opts |> Keyword.get(:parsers, [default_parser]) |> Enum.map(&module_name/1)

    quote do
      @otp_app unquote(otp_app)
      @dsl unquote(dsl)
      @overrides unquote(overrides)
      @mod unquote(mod)
      @parsers unquote(parsers)
      @generators unquote(generators)

      def parsers, do: @parsers
      def dsl, do: @dsl

      defmacro __using__(opts) do
        mod = __CALLER__.module
        opts = Keyword.put(opts, :caller_module, mod)

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
          @opts unquote(opts)
        end
      end

      defmacro __before_compile__(_env) do
        mod = __CALLER__.module
        opts = Module.get_attribute(mod, :opts)
        dsl = Module.get_attribute(mod, :dsl)
        definition = Module.get_attribute(mod, :definition)

        code =
          if definition do
            parsers = Module.get_attribute(mod, :parsers)
            generators = Module.get_attribute(mod, :generators)

            definition = Diesel.Dsl.validate!(dsl, definition)
            Module.put_attribute(mod, :definition, definition)

            definition = Enum.reduce(parsers, definition, & &1.parse(&2, opts))

            generated_code =
              generators
              |> Enum.flat_map(&[&1.generate(definition, opts)])
              |> Enum.reject(&is_nil/1)

            [definition_ast() | generated_code]
          else
            []
          end

        if opts[:debug] do
          code
          |> Macro.to_string()
          |> Code.format_string!()
          |> IO.puts()
        end

        code
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

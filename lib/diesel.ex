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

  @doc """
  Compiles the raw definition and returns a compiled version of it

  The obtained structure is the result of applying the configured list of parsers to the raw
  internal definition and then compiling it according to the rules implemented by packages.
  """
  @callback compile(context :: map()) :: term()

  import Diesel.Naming

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    mod = __CALLER__.module
    default_dsl = Module.concat(mod, Dsl)
    default_parser = Module.concat(mod, Parser)

    dsl = opts |> Keyword.get(:dsl, default_dsl) |> module_name()
    overrides = Keyword.get(opts, :overrides, [])
    compilation_flags = Keyword.get(opts, :compilation_flags, [])

    generators =
      Keyword.get(opts, :generators, []) ++
        (otp_app
         |> Application.get_env(mod, [])
         |> Keyword.get(:generators, []))

    generators = Enum.map(generators, &module_name/1)

    parsers =
      Keyword.get(opts, :parsers, [default_parser]) ++
        (otp_app
         |> Application.get_env(mod, [])
         |> Keyword.get(:parsers, []))

    parsers = Enum.map(compilation_flags, &Diesel.Parser.named/1) ++ parsers

    parsers = Enum.map(parsers, &module_name/1)

    quote do
      @otp_app unquote(otp_app)
      @dsl unquote(dsl)
      @overrides unquote(overrides)
      @mod unquote(mod)
      @parsers unquote(parsers)
      @generators unquote(generators)

      def parsers, do: @parsers
      def dsl, do: @dsl

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

        if definition do
          parsers = Module.get_attribute(mod, :parsers)
          generators = Module.get_attribute(mod, :generators)
          Diesel.Dsl.validate!(dsl, definition)

          definition = Enum.reduce(parsers, definition, & &1.parse(mod, &2))

          generated_code =
            generators
            |> Enum.flat_map(&[&1.generate(mod, definition)])
            |> Enum.reject(&is_nil/1)

          [definition_ast() | generated_code]
        else
          []
        end
      end

      defp definition_ast do
        quote do
          @impl Diesel
          def definition, do: @definition
        end
      end
    end
  end

  @doc "Returns all children elements matching the given tag"
  @spec children(element(), tag()) :: [element()]
  def children({_, _, children}, name) when is_list(children), do: elements(children, name)

  @doc "Returns all elements matching the given name"
  @spec elements([element()], tag()) :: [element()]
  def elements(elements, name) when is_list(elements),
    do: for({^name, _, _} = element <- elements, do: element)

  @doc "Returns the first child element matching the given name, from the given definition"
  @spec child(element(), tag()) :: element() | nil
  def child({_, _, _} = element, name) do
    element
    |> children(name)
    |> List.first()
  end

  @doc "Returns the first child of the given element, or list of elements"
  @spec child(element() | [element()]) :: any()
  def child({_, _, [child | _]}), do: child
  def child(nodes) when is_list(nodes), do: Enum.map(nodes, &child/1)
  def child(nil), do: nil
end

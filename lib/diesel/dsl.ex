defmodule Diesel.Dsl do
  @moduledoc """
  Defines the syntax provided by a DSL.

  Simple usage:

  ```elixir
  defmodule MyApp.Fsm.Dsl do
    use Diesel.Dsl,
      otp_app: :my_app,
      root: :fsm,
      tags: [
        :state,
        :on,
        :action,
        :next
      ]
  end
  ```

  Please check the documentation for more info on how to extend DSLs via `packages`
  """
  alias Diesel.Tag

  import Diesel.Naming

  defmacro __using__(opts) do
    dsl = __CALLER__.module
    otp_app = Keyword.fetch!(opts, :otp_app)
    default_root_tag = dsl |> Module.split() |> Enum.drop(-1) |> List.last()
    default_root_tag = Module.concat(dsl, default_root_tag)

    root = opts |> Keyword.get(:root, default_root_tag) |> module_name()
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

    tags = tags |> Enum.map(&module_name/1) |> Enum.uniq()
    tags_by_name = Enum.reduce(tags, %{}, &Map.put(&2, Tag.name(&1), &1))

    tag_names = Map.keys(tags_by_name)
    root_name = Tag.name(root)

    tag_names = tag_names -- [root_name]

    tags_by_name = Map.put(tags_by_name, root_name, root)

    quote do
      @before_compile Diesel.Dsl
      @root unquote(root_name)
      @tag_names unquote(tag_names)
      @all_tags_names [@root | @tag_names]
      @tags_by_name unquote(Macro.escape(tags_by_name))
      @packages unquote(packages)
      @locals_without_parens for tag <- @all_tags_names, do: {tag, :*}

      def root, do: @root
      def tags, do: @all_tags_names

      @doc """
      Returns the list of locals without parens function signatures, so that they can be easily
      included in .formatter.exs files
      """
      @spec locals_without_parens() :: keyword()
      def locals_without_parens, do: @locals_without_parens

      def validate({tag, _, children} = node) do
        with :ok <- validate(children), do: validate_node(node)
      end

      def validate(nodes) when is_list(nodes) do
        Enum.reduce_while(nodes, :ok, fn node, _ ->
          case validate(node) do
            :ok -> {:cont, :ok}
            error -> {:halt, error}
          end
        end)
      end

      def validate(_), do: :ok

      defp validate_node({tag, _, _} = node) do
        case Map.get(@tags_by_name, tag) do
          nil ->
            {:error, "Unsupported tag '#{inspect(tag)}'"}

          tag ->
            with {:error, reason} <- Tag.validate(tag, node) do
              {:error, "in tag '#{Tag.name(tag)}'. #{reason}"}
            end
        end
      end

      defmacro unquote(root_name)(do: {:__block__, [], children}) do
        quote do
          @definition {unquote(@root), [], unquote(children)}
        end
      end

      defmacro unquote(root_name)(do: child) do
        quote do
          @definition {unquote(@root), [], [unquote(child)]}
        end
      end

      defmacro unquote(root_name)(attrs, do: {:__block__, [], children}) do
        quote do
          @definition {unquote(@root), unquote(attrs), unquote(children)}
        end
      end

      defmacro unquote(root_name)(attrs, do: child) do
        quote do
          @definition {unquote(@root), unquote(attrs), [unquote(child)]}
        end
      end

      defmacro unquote(root_name)(attrs, child) do
        quote do
          @definition {unquote(@root), unquote(attrs), [unquote(child)]}
        end
      end

      defmacro unquote(root_name)(name, attrs, do: {:__block__, [], children}) do
        quote do
          @definition {unquote(@root), unquote(Keyword.put(attrs, :name, name)),
                       unquote(children)}
        end
      end

      defmacro unquote(root_name)(name, attrs, do: child) do
        quote do
          @definition {unquote(@root), unquote(Keyword.put(attrs, :name, name)), [unquote(child)]}
        end
      end

      unquote_splicing(
        Enum.map(tag_names, fn tag ->
          quote do
            defmacro unquote(tag)(attrs, do: {:__block__, _, children}) when is_list(attrs) do
              {:{}, [line: 1], [unquote(tag), attrs, children]}
            end

            defmacro unquote(tag)(attr, do: {:__block__, _, children}) do
              {:{}, [line: 1], [unquote(tag), [name: attr], children]}
            end

            defmacro unquote(tag)(name, attrs, do: {:__block__, _, children}) do
              {:{}, [line: 1], [unquote(tag), Keyword.put(attrs, :name, name), children]}
            end

            defmacro unquote(tag)(attrs, do: child) when is_list(attrs) do
              {:{}, [line: 1], [unquote(tag), attrs, [child]]}
            end

            defmacro unquote(tag)(attr, do: child) do
              {:{}, [line: 1], [unquote(tag), [name: attr], [child]]}
            end

            defmacro unquote(tag)(name, attrs, do: child) do
              {:{}, [line: 1], [unquote(tag), Keyword.put(attrs, :name, name), [child]]}
            end

            defmacro unquote(tag)(do: {:__block__, _, children}) do
              {:{}, [line: 1], [unquote(tag), [], children]}
            end

            defmacro unquote(tag)(do: child) do
              {:{}, [line: 1], [unquote(tag), [], [child]]}
            end

            defmacro unquote(tag)(attrs) when is_list(attrs) do
              if Keyword.keyword?(attrs) do
                {:{}, [line: 1], [unquote(tag), attrs, []]}
              else
                {:{}, [line: 1], [unquote(tag), [], attrs]}
              end
            end

            defmacro unquote(tag)(child) do
              {:{}, [line: 1], [unquote(tag), [], [child]]}
            end

            defmacro unquote(tag)(name, attrs) when is_list(attrs) do
              {:{}, [line: 1], [unquote(tag), Keyword.put(attrs, :name, name), []]}
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

  @doc false
  def validate!(dsl, definition) do
    with {:error, reason} <- dsl.validate(definition) do
      raise "invalid syntax #{reason}"
    end
  end
end

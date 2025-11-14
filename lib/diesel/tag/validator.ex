defmodule Diesel.Tag.Validator do
  @moduledoc """
  Helper module that validates a tag against a schema.

  Validation of tags is only available for structured tags, and is applied right after tag parsing
  and before code generation.
  """

  @doc """
  Validates the given node, against the given schema
  """
  @spec validate(node :: tuple(), schema :: tuple()) :: :ok | {:error, any()}
  def validate({tag, attrs, children} = node, schema) do
    attr_specs = specs(schema, :attribute)
    child_specs = specs(schema, :child)

    with :ok <- validate_unexpected_attributes(attr_specs, attrs),
         {:ok, attrs} <- validate_expected_attributes(attr_specs, attrs),
         :ok <- validate_expected_children(child_specs, children),
         :ok <- validate_unexpected_children(child_specs, children) do
      {:ok, {tag, attrs, children}}
    else
      {:error, reason} ->
        {:error, reason <> ". In: #{inspect(node)}"}
    end
  end

  defp validate_expected_attributes(specs, attrs) do
    with {:ok, named_attrs} <- validate_expected_named_attributes(specs, attrs),
         {:ok, anonymous_attrs} <- validate_expected_anonymous_attributes(specs, attrs) do
      {:ok, Enum.uniq(named_attrs ++ anonymous_attrs)}
    end
  end

  defp validate_expected_named_attributes(specs, attrs) do
    specs = Enum.reject(specs, fn spec -> spec[:name] == :* end)

    with validated_attrs when is_list(validated_attrs) <-
           Enum.reduce_while(specs, [], fn spec, validated_attrs ->
             attr_name = Keyword.fetch!(spec, :name)
             attr_value = attrs[attr_name]

             case validate_attribute_value(spec, attr_name, attr_value) do
               {:ok, attr} -> {:cont, [attr | validated_attrs]}
               {:error, reason} -> {:halt, attribute_error(attr_name, attr_value, reason)}
             end
           end),
         do: {:ok, Enum.reverse(validated_attrs)}
  end

  defp validate_expected_anonymous_attributes(specs, attrs) do
    specs
    |> Enum.find(&(&1[:name] == :*))
    |> validate_expected_anonymous_attributes_using_spec(attrs)
  end

  defp validate_expected_anonymous_attributes_using_spec(nil, _attrs), do: {:ok, []}

  defp validate_expected_anonymous_attributes_using_spec(spec, attrs) do
    with validated_attrs when is_list(validated_attrs) <-
           Enum.reduce_while(attrs, [], fn {attr_name, attr_value}, validated_attrs ->
             case validate_attribute_value(spec, attr_name, attr_value) do
               {:ok, attr} -> {:cont, [attr | validated_attrs]}
               {:error, reason} -> {:halt, attribute_error(attr_name, attr_value, reason)}
             end
           end),
         do: {:ok, Enum.reverse(validated_attrs)}
  end

  defp validate_attribute_value(spec, attr_name, attr_value) do
    kind = Keyword.fetch!(spec, :kind)
    default = Keyword.get(spec, :default, nil)
    required = Keyword.get(spec, :required, true)
    allowed_values = Keyword.get(spec, :in, [])
    attr_value = attr_value

    with {:ok, validated_value} <- validate_value(attr_value, kind, required, default),
         :ok <- validate_allowed(validated_value, allowed_values) do
      {:ok, {attr_name, validated_value}}
    end
  end

  defp attribute_error(name, value, reason) do
    {:error, "Error in attribute '#{name}' of value '#{value}': #{reason}"}
  end

  defp validate_unexpected_attributes(specs, attrs) do
    Enum.reduce_while(attrs, :ok, fn attr, _ ->
      attr_name =
        case attr do
          {attr_name, _} -> attr_name
          attr_name -> attr_name
        end

      if expected_name?(attr_name, specs) do
        {:cont, :ok}
      else
        {:halt, {:error, "Unexpected attribute '#{attr_name}'"}}
      end
    end)
  end

  defp validate_expected_children(specs, children) do
    Enum.reduce_while(specs, :ok, fn spec, _ ->
      children = find_matching_children(children, spec)

      min = Keyword.get(spec, :min, 0)
      max = Keyword.get(spec, :max, :any)
      actual = Enum.count(children)

      case validate_expected_count(actual, min, max) do
        :ok ->
          {:cont, :ok}

        {:error, reason} ->
          children_description = children_description(spec)
          {:halt, {:error, "Unexpected number of children #{children_description}. #{reason}"}}
      end
    end)
  end

  defp children_description(spec) do
    if spec[:name] do
      "of name '#{spec[:name]}'"
    else
      "of kind '#{spec[:kind]}'"
    end
  end

  defp find_matching_children(children, spec) do
    name = Keyword.get(spec, :name)
    kind = spec |> Keyword.get(:kind, :tag) |> ensure_valid_kind!(spec)

    find_matching_children(children, name, kind)
  end

  defp find_matching_children(children, nil, :any) do
    children
  end

  defp find_matching_children(children, name, :tag) do
    Enum.filter(children, fn
      {tag, _, _} -> tag == name
      _ -> false
    end)
  end

  defp find_matching_children(children, nil, kind) do
    Enum.filter(children, fn child ->
      tag_kind(child) == kind
    end)
  end

  @valid_kinds [:tag, :atom, :module, :boolean, :number, :string, :any, :integer, :float]

  defp ensure_valid_kind!(kind, spec) do
    unless Enum.member?(@valid_kinds, kind) do
      raise "Found kind '#{kind}', in tag definition, but only #{inspect(@valid_kinds)} are
        accepted. In: #{inspect(spec)}"
    end

    kind
  end

  defp validate_expected_count(0, min, _) when min > 0 do
    {:error, "Found 0, expected at least #{min}"}
  end

  defp validate_expected_count(count, _, 1) when count > 1 do
    {:error, "Found #{count}, expected at most 1"}
  end

  defp validate_expected_count(_, _, _), do: :ok

  defp validate_unexpected_children(specs, children) do
    Enum.reduce_while(children, :ok, fn child, _ ->
      case validate_child(child, specs) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_child({name, _, _} = tag, specs) do
    if expected_name?(name, specs) do
      :ok
    else
      {:error, "Found child with unexpected name: #{inspect(tag)}"}
    end
  end

  defp validate_child(value, specs) do
    kind = tag_kind(value)

    if expected_child_kind?(kind, specs) do
      :ok
    else
      {:error, "Found child '#{inspect(value)}' of unexpected kind '#{kind}'"}
    end
  end

  defp expected_name?(name, specs),
    do:
      Enum.find(specs, fn spec ->
        is_nil(spec[:name]) || spec[:name] == :* || spec[:name] == name
      end)

  defp expected_child_kind?(kind, specs) do
    Enum.find(specs, fn spec -> spec[:kind] in [:any, :*] || spec[:kind] == kind end)
  end

  defp tag_kind({_, _, _}), do: :tag
  defp tag_kind(tag) when is_number(tag), do: :number
  defp tag_kind(tag) when is_binary(tag), do: :string

  defp tag_kind(tag) when is_atom(tag) do
    if tag |> to_string() |> String.starts_with?("Elixir."), do: :module, else: :atom
  end

  defp tag_kind(other) do
    raise "Unrecognized element in dsl: #{inspect(other)}"
  end

  defp validate_value(nil, kind, true, nil),
    do: {:error, "expected a value of type #{kind}, got nil and no default was provided"}

  defp validate_value(nil, _kind, _required, default), do: {:ok, default}

  defp validate_value(value, :any, _required, _default), do: {:ok, value}
  defp validate_value(values, :list, _required, _default) when is_list(values), do: {:ok, values}

  defp validate_value(value, :string, _required, _default) when is_binary(value), do: {:ok, value}

  defp validate_value(value, :string, _required, _default),
    do: {:error, "expected a string, got #{inspect(value)}"}

  defp validate_value(value, :number, _required, _default) when is_number(value), do: {:ok, value}

  defp validate_value(value, :number, _required, _default),
    do: {:error, "Expected a number, got #{inspect(value)}"}

  defp validate_value(value, :integer, _required, _default) when is_integer(value),
    do: {:ok, value}

  defp validate_value(value, :integer, _required, _default),
    do: {:error, "Expected an integer, got #{inspect(value)}"}

  defp validate_value(value, :float, _required, _default) when is_float(value),
    do: {:ok, value}

  defp validate_value(value, :float, _required, _default),
    do: {:error, "Expected a float, got #{inspect(value)}"}

  defp validate_value(value, :boolean, _required, _default) when is_boolean(value),
    do: {:ok, value}

  defp validate_value(value, :boolean, _required, _default),
    do: {:error, "Expected a boolean, got #{inspect(value)}"}

  defp validate_value(value, :atom, _required, _default) when is_atom(value), do: {:ok, value}

  defp validate_value(value, :atom, _required, _default),
    do: {:error, "Expected an atom, got #{inspect(value)}"}

  defp validate_value(value, :module, _required, _default) when is_atom(value), do: {:ok, value}

  defp validate_value(value, :module, _required, _default),
    do: {:error, "Expected an module, got #{inspect(value)}"}

  defp validate_value([], :strings, true, default) when default == [] or is_nil(default),
    do: {:error, "Expected a non-empty list of strings, got none"}

  defp validate_value([], :strings, required, default)
       when is_list(default) and length(default) > 0,
       do: validate_value(default, :strings, required, default)

  defp validate_value(values, :strings, _required, _default) when is_list(values),
    do: validate_values(values, :string)

  defp validate_value([], :numbers, true, default) when default == [] or is_nil(default),
    do: {:error, "Expected a non-empty list of numbers, got none"}

  defp validate_value([], :numbers, required, default)
       when is_list(default) and length(default) > 0,
       do: validate_value(default, :numbers, required, default)

  defp validate_value(values, :numbers, _required, _default) when is_list(values),
    do: validate_values(values, :number)

  defp validate_value([], :integers, true, default) when default == [] or is_nil(default),
    do: {:error, "Expected a non-empty list of integers, got none"}

  defp validate_value([], :integers, required, default)
       when is_list(default) and length(default) > 0,
       do: validate_value(default, :integer, required, default)

  defp validate_value(values, :integers, _required, _default) when is_list(values),
    do: validate_values(values, :integer)

  defp validate_value([], :floats, true, default) when default == [] or is_nil(default),
    do: {:error, "Expected a non-empty list of floats, got none"}

  defp validate_value([], :floats, required, default)
       when is_list(default) and length(default) > 0,
       do: validate_value(default, :float, required, default)

  defp validate_value(values, :floats, _required, _default) when is_list(values),
    do: validate_values(values, :float)

  defp validate_value([], :atoms, true, default) when default == [] or is_nil(default),
    do: {:error, "expected a non-empty list of atoms, got none"}

  defp validate_value([], :atoms, required, default)
       when is_list(default) and length(default) > 0,
       do: validate_value(default, :atoms, required, default)

  defp validate_value(values, :atoms, _required, _default) when is_list(values),
    do: validate_values(values, :atom)

  defp validate_value(value, :*, _, _default), do: {:ok, value}

  defp validate_value(value, kinds, required, default) when is_list(kinds) do
    Enum.reduce_while(
      kinds,
      {:error, "expected the type to be one of #{inspect(kinds)}"},
      fn kind, error ->
        case validate_value(value, kind, required, default) do
          {:ok, value} -> {:halt, {:ok, value}}
          {:error, _} -> {:cont, error}
        end
      end
    )
  end

  defp validate_value(value, kind, _, _default) do
    {:error, "don't know how to validate #{inspect(value)} of type #{inspect(kind)}"}
  end

  defp validate_values(values, kind) do
    values
    |> Enum.reduce_while([], fn value, acc ->
      case validate_value(value, kind, true, nil) do
        {:ok, value} -> {:cont, [value | acc]}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> then(fn
      values when is_list(values) -> {:ok, Enum.reverse(values)}
      {:error, _} = error -> error
    end)
  end

  defp validate_allowed(_value, []), do: :ok

  defp validate_allowed(values, allowed) when is_list(values) do
    Enum.reduce(values, :ok, fn value, _ ->
      case validate_allowed(value, allowed) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_allowed(value, allowed) do
    if Enum.member?(allowed, value) do
      :ok
    else
      {:error, "Value #{inspect(value)} is not allowed. Expected one of #{inspect(allowed)}"}
    end
  end

  defp specs({_, _, specs}, kind) when kind in [:attribute, :child] do
    specs
    |> Enum.reduce([], fn
      {^kind, spec, _}, acc -> [spec | acc]
      _, acc -> acc
    end)
    |> Enum.reverse()
  end
end

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
  def validate({_tag, attrs, children}, schema) do
    attr_specs = specs(schema, :attribute)
    child_specs = specs(schema, :child)

    with :ok <- validate_expected_attributes(attr_specs, attrs),
         :ok <- validate_unexpected_attributes(attr_specs, attrs),
         :ok <- validate_expected_children(child_specs, children) do
      validate_unexpected_children(child_specs, children)
    end
  end

  defp validate_expected_attributes(specs, attrs) do
    Enum.reduce_while(specs, :ok, fn spec, _ ->
      attr_name = spec[:name]
      default = Keyword.get(spec, :default, nil)
      kind = Keyword.get(spec, :kind, :string)
      required = Keyword.get(spec, :required, true)
      allowed_values = Keyword.get(spec, :allowed, [])
      attr_value = attrs[attr_name] || default

      with :ok <- validate_value(attr_value, kind, required),
           :ok <- validate_allowed(attr_value, allowed_values) do
        {:cont, :ok}
      else
        {:error, reason} ->
          {:halt, attribute_error(attr_name, attr_value, reason)}
      end
    end)
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

  @valid_kinds [:tag, :atom, :module, :boolean, :number, :string, :any]

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
    do: Enum.find(specs, fn spec -> is_nil(spec[:name]) || spec[:name] == name end)

  defp expected_child_kind?(kind, specs) do
    Enum.find(specs, fn spec -> spec[:kind] == :any || spec[:kind] == kind end)
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

  defp validate_value(nil, _, true), do: {:error, "value is missing"}
  defp validate_value(nil, _, false), do: :ok

  defp validate_value(value, :string, _) when not is_binary(value),
    do: {:error, "expected a string, got #{inspect(value)}"}

  defp validate_value(value, :number, _) when not is_number(value),
    do: {:error, "Expected a number, got #{inspect(value)}"}

  defp validate_value(value, :boolean, _) when not is_boolean(value),
    do: {:error, "Expected a boolean, got #{inspect(value)}"}

  defp validate_value(value, :atom, _) when not is_atom(value),
    do: {:error, "Expected an atom, got #{inspect(value)}"}

  defp validate_value([], :strings, true),
    do: {:error, "Expected a list of strings, got an empty list"}

  defp validate_value(values, :strings, _) when is_list(values) do
    Enum.reduce_while(values, :ok, fn value, _ ->
      case validate_value(value, :string, true) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_value([], :number, true),
    do: {:error, "Expected a list of numbers, got an empty list"}

  defp validate_value(values, :numbers, _) when is_list(values) do
    Enum.reduce_while(values, :ok, fn value, _ ->
      case validate_value(value, :number, true) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_value([], :atoms, true),
    do: {:error, "expected a list of atoms, got an empty list"}

  defp validate_value(values, :atoms, _) when is_list(values) do
    Enum.reduce_while(values, :ok, fn value, _ ->
      case validate_value(value, :atom, true) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_value(_value, _kind, _required), do: :ok

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

  defp specs({_, _, specs}, kind) do
    specs
    |> Enum.reduce([], fn
      {^kind, spec, _}, acc -> [spec | acc]
      _, acc -> acc
    end)
    |> Enum.reverse()
  end
end

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
        {:error, reason} -> {:halt, {:error, "Error in attribute '#{attr_name}'. #{reason}"}}
      end
    end)
  end

  defp validate_unexpected_attributes(specs, attrs) do
    Enum.reduce_while(attrs, :ok, fn attr, _ ->
      attr_name =
        case attr do
          {attr_name, _} -> attr_name
          attr_name -> attr_name
        end

      if expected?(attr_name, specs) do
        {:cont, :ok}
      else
        {:halt, {:error, "Unexpected attribute '#{attr_name}'"}}
      end
    end)
  end

  defp validate_expected_children(specs, children) do
    Enum.reduce_while(specs, :ok, fn spec, _ ->
      name = spec[:name]
      children = Enum.filter(children, fn {tag, _, _} -> tag == name end)
      min = Keyword.get(spec, :min, 0)
      max = Keyword.get(spec, :max, :any)
      actual = Enum.count(children)

      case validate_expected_count(actual, min, max) do
        :ok ->
          {:cont, :ok}

        {:error, reason} ->
          {:halt, {:error, "Unexpected number of children of type '#{name}'. #{reason}"}}
      end
    end)
  end

  defp validate_expected_count(0, min, _) when min > 0 do
    {:error, "Found 0, expected at least #{min}"}
  end

  defp validate_expected_count(count, _, 1) when count > 1 do
    {:error, "Found #{count}, expected at most 1"}
  end

  defp validate_expected_count(_, _, _), do: :ok

  defp validate_unexpected_children(specs, children) do
    Enum.reduce_while(children, :ok, fn {name, _, _}, _ ->
      if expected?(name, specs) do
        {:cont, :ok}
      else
        {:halt, {:error, "Unexpected child '#{name}'"}}
      end
    end)
  end

  defp expected?(name, specs), do: Enum.find(specs, fn spec -> spec[:name] == name end) != nil

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

defmodule Diesel.Templating do
  @moduledoc """
  Liquid templating support for DSLs during compilation.

  Example:

  ```elixir
  defmodule Paper do
    use Latex

    latex do
      document size: "{{ doc.size }}" do
        ...
      end
    end
  end

  iex> context = %{doc: %{size: "a4"}}
  iex> Paper.compile(context)
  ```
  """

  def render!(tpl, vars) when is_list(vars) do
    render!(tpl, Map.new(vars))
  end

  def render!(tpl, vars) when is_map(vars) do
    case render(tpl, vars) do
      {:ok, str} ->
        str

      {:error, reason} ->
        raise_error(tpl, vars, reason)

      {:error, reason, _} ->
        raise_error(tpl, vars, reason)
    end
  end

  defp raise_error(tpl, vars, error) do
    raise "Error rendering template #{tpl} with vars #{inspect(vars)}: #{inspect(error)}"
  end

  defp render(tpl, vars) do
    with {:ok, tpl} <- Solid.parse(tpl),
         {:ok, rendered} <- Solid.render(tpl, string_keys(vars), strict_variables: true) do
      {:ok, to_string(rendered)}
    end
  end

  defp string_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} ->
      {to_string(key), string_keys(value)}
    end)
    |> Enum.into(%{})
  end

  defp string_keys(items) when is_list(items), do: Enum.map(items, &string_keys/1)
  defp string_keys(other), do: other
end

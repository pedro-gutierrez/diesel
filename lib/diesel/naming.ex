defmodule Diesel.Naming do
  @moduledoc """
  Naming utilities
  """

  @doc "Return a module name"
  def module_name({:__aliases__, _, mod}), do: Module.concat(mod)
  def module_name(atom) when is_atom(atom), do: atom
end

defmodule Diesel.Tag do
  @moduledoc """
  Tags are the building blocks for the syntax offered by a Diesel DSL.

  Usage:

  ```elixir
  defmodule MyApp.Fsm.Dsl.State do
    use Diesel.Tag

    attribute :name, kind: :atom
    child :on, :min: 0
  end
  ```

  For more information on how to define structured tags, please check the examples provided in the documentation and in tests
  """

  use Diesel,
    otp_app: :diesel,
    parsers: [],
    generators: [
      Diesel.Tag.Generator
    ]

  @doc """
  Validates the given definition node against the given tag

  This function supports both structured and plain atom tags.

  For plain atom tags, this function will always return success.
  """
  def validate(tag, node), do: if(structured?(tag), do: tag.validate(node), else: :ok)

  @doc """
  Returns whether a tag is structured or not
  """
  def structured?(tag) do
    if tag |> to_string() |> String.starts_with?("Elixir."), do: Code.ensure_compiled!(tag)

    function_exported?(tag, :name, 0) && function_exported?(tag, :validate, 1)
  end

  @doc """
  Returns the name of the given tag

  For unstructured, plain atom tags, the name is simply the atom itself
  """
  def name(tag), do: if(structured?(tag), do: tag.name(), else: tag)
end

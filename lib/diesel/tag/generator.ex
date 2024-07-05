defmodule Diesel.Tag.Generator do
  @moduledoc false
  @behaviour Diesel.Generator

  @impl Diesel.Generator
  def generate(schema, opts) do
    tag = Keyword.fetch!(opts, :caller_module)

    tag_name = tag |> Module.split() |> List.last() |> Macro.underscore() |> String.to_atom()

    quote do
      alias Diesel.Tag.Validator

      @tag_name unquote(tag_name)
      @schema unquote(Macro.escape(schema))

      def name, do: @tag_name

      def validate({@tag_name, _, _} = node) do
        Validator.validate(node, @schema)
      end
    end
  end
end

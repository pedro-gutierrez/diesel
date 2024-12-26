defmodule Diesel.ValidatorTest do
  use ExUnit.Case

  alias Diesel.Tag.Validator

  describe "validate/2" do
    test "allows unspecified kinds of literal children" do
      node = {:equal, [], [1, "b"]}
      schema = {:tag, [], [{:child, [kind: :any, min: 2, max: 2], []}]}
      assert :ok == Validator.validate(node, schema)
    end

    test "allows unspecified kinds of node children" do
      node = {:equal, [], [{:path, [], ["current_user.name"]}, "b"]}
      schema = {:tag, [], [{:child, [kind: :any, min: 2, max: 2], []}]}
      assert :ok == Validator.validate(node, schema)
    end

    test "allows generic attributes with unspecified names and kinds" do
      node = {:conditions, [{:a, 1}, {:b, 2}], []}
      schema = {:tag, [], [{:attribute, [name: :*, kind: :*, min: 1], []}]}

      assert :ok == Validator.validate(node, schema)
    end
  end
end

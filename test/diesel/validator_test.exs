defmodule Diesel.ValidatorTest do
  use ExUnit.Case

  alias Diesel.Tag.Validator

  describe "validate/2" do
    test "allows unspecified kinds of literal children" do
      node = {:equal, [], [1, "b"]}
      schema = {:tag, [], [{:child, [kind: :any, min: 2, max: 2], []}]}
      assert {:ok, node} == Validator.validate(node, schema)
    end

    test "allows unspecified kinds of node children" do
      node = {:equal, [], [{:path, [], ["current_user.name"]}, "b"]}
      schema = {:tag, [], [{:child, [kind: :any, min: 2, max: 2], []}]}
      assert {:ok, node} == Validator.validate(node, schema)
    end

    test "allows generic attributes with unspecified names and kinds" do
      node = {:conditions, [{:a, 1}, {:b, 2}], []}
      schema = {:tag, [], [{:attribute, [name: :*, kind: :*, min: 1], []}]}

      assert {:ok, node} == Validator.validate(node, schema)
    end

    test "validates attributes with a default boolean set to false" do
      node = {:conditions, [], []}
      schema = {:tag, [], [{:attribute, [name: :public, kind: :boolean, default: false], []}]}
      assert {:ok, {:conditions, [{:public, false}], []}} == Validator.validate(node, schema)
    end

    test "validates attributes with a default list" do
      node = {:conditions, [], []}
      schema = {:tag, [], [{:attribute, [name: :roles, kind: :atoms, default: [:user]], []}]}
      assert {:ok, {:conditions, [{:roles, [:user]}], []}} == Validator.validate(node, schema)
    end

    test "ignores default values" do
      node = {:conditions, [active: true], []}
      schema = {:tag, [], [{:attribute, [name: :active, kind: :boolean, default: false], []}]}
      assert {:ok, {:conditions, [{:active, true}], []}} == Validator.validate(node, schema)
    end
  end
end

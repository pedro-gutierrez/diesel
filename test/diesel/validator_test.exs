defmodule Diesel.ValidatorTest do
  use ExUnit.Case

  alias Diesel.Tag.Validator

  describe "validate/2" do
    test "allows attributes of type integer" do
      node = {:conditions, [timeout: 5], []}
      schema = {:tag, [], [{:attribute, [name: :timeout, kind: :integer], []}]}
      assert {:ok, {:conditions, [{:timeout, 5}], []}} == Validator.validate(node, schema)
    end

    test "allows attributes of type any" do
      node = {:conditions, [default: :foo], []}
      schema = {:tag, [], [{:attribute, [name: :default, kind: :any], []}]}
      assert {:ok, {:conditions, [{:default, :foo}], []}} == Validator.validate(node, schema)
    end

    test "allows attributes of type list" do
      node = {:conditions, [in: [1, 2]], []}
      schema = {:tag, [], [{:attribute, [name: :in, kind: :list], []}]}
      assert {:ok, {:conditions, [{:in, [1, 2]}], []}} == Validator.validate(node, schema)
    end

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

    test "validates optional attributes of type number with a default value" do
      node = {:conditions, [], []}

      schema =
        {:tag, [],
         [{:attribute, [name: :timeout, kind: :number, default: 0, required: false], []}]}

      assert {:ok, {:conditions, [{:timeout, 0}], []}} == Validator.validate(node, schema)
    end

    test "validates optional attributes of type atom, with with a list of allows values and a default value" do
      node = {:route, [], []}

      schema =
        {:tag, [],
         [
           {:attribute,
            [
              name: :method,
              kind: :atom,
              default: :get,
              required: false,
              in: [:get, :post, :put, :delete]
            ], []}
         ]}

      assert {:ok, {:route, [{:method, :get}], []}} == Validator.validate(node, schema)
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

    test "validates attribute of type any with a default value" do
      node = {:conditions, [], []}
      schema = {:tag, [], [{:attribute, [name: :default, kind: :any, default: :foo], []}]}
      assert {:ok, {:conditions, [{:default, :foo}], []}} == Validator.validate(node, schema)
    end

    test "validates attribute of type list with a default value" do
      node = {:conditions, [], []}
      schema = {:tag, [], [{:attribute, [name: :in, kind: :list, default: [1, 2]], []}]}
      assert {:ok, {:conditions, [{:in, [1, 2]}], []}} == Validator.validate(node, schema)
    end

    test "ignores default values if a value is already given" do
      node = {:conditions, [active: true], []}
      schema = {:tag, [], [{:attribute, [name: :active, kind: :boolean, default: false], []}]}
      assert {:ok, {:conditions, [{:active, true}], []}} == Validator.validate(node, schema)
    end

    test "detects unexpected attributes" do
      node = {:conditions, [active: true, unexpected: "value"], []}
      schema = {:tag, [], [{:attribute, [name: :active, kind: :boolean, default: false], []}]}

      assert {:error,
              "Unexpected attribute 'unexpected'" <>
                ". In: {:conditions, [active: true, unexpected: \"value\"], []}"} ==
               Validator.validate(node, schema)
    end
  end
end

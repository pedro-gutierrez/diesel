defmodule DieselTest do
  use ExUnit.Case

  describe "dsls" do
    test "can be extended" do
      for tag <- Latex.Dsl.Music.tags() do
        assert tag in Latex.Dsl.tags()
      end
    end

    test "produce an internal, tree-like structure definition" do
      assert [{:document, [size: :a4], _}] = Paper.definition()
    end
  end
end

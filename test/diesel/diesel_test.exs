defmodule DieselTest do
  use ExUnit.Case

  describe "dsls" do
    test "have an extenstible syntax" do
      for tag <- Latex.Dsl.Music.tags() do
        assert tag in Latex.Dsl.tags()
      end
    end

    test "produce an internal, tree-like structure definition" do
      assert {:latex, [version: 3.14159265],
              [
                {:document, [size: "{{ document.size }}"],
                 [
                   {:packages, [:babel, :graphics], []},
                   {:section, _, _}
                 ]}
              ]} = Paper.definition()

      assert {:latex, [], [{:document, _, _}, {:document, _, _}]} = Papers.definition()
    end

    test "can be compiled" do
      assert {:latex, [version: 3.14159265],
              [
                {:document, [size: "a4"],
                 [
                   {:package, [name: :babel], []},
                   {:package, [name: :graphics], []},
                   {:section, [numbered: true, title: "Introduction"], _}
                 ]}
              ]} = Paper.compile(%{document: %{size: :a4}})
    end

    test "translate into actual Elixir code" do
      assert Paper.pdf() =~ "%PDF"
      assert Paper.html() =~ "<html>"
    end
  end
end

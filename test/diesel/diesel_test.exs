defmodule DieselTest do
  use ExUnit.Case

  describe "dsls" do
    test "have a default root tag" do
      assert Fsm.Dsl.root() == :fsm
    end

    test "have a default parser" do
      assert Fsm.parsers() == [Fsm.Parser]
    end

    test "have a default dsl" do
      assert Fsm.dsl() == Fsm.Dsl
    end

    test "are made of tags" do
      assert [:fsm, :action, :next, :on, :state] == Fsm.Dsl.tags()
    end

    test "export their formatter configuration" do
      assert [fsm: :*, action: :*, next: :*, on: :*, state: :*] == Fsm.Dsl.locals_without_parens()
    end

    test "produce an internal definition" do
      assert {
               :fsm,
               [name: "payment"],
               [
                 {:state, [name: :pending],
                  [
                    {:on, [event: :created],
                     [{:action, [], [SendToGateway]}, {:next, [state: :sent], []}]}
                  ]},
                 {
                   :state,
                   [name: :sent, timeout: 60],
                   [
                     {:on, [event: :success],
                      [{:action, [], [NotifyParties]}, {:next, [state: :accepted], []}]},
                     {:on, [event: :error],
                      [{:action, [], [NotifyParties]}, {:next, [state: :declined], []}]},
                     {:on, [event: :timeout],
                      [{:action, [], [NotifyParties]}, {:next, [state: :declined], []}]}
                   ]
                 },
                 {:state, [name: :accepted], []},
                 {:state, [name: :declined], []}
               ]
             } == Payment.definition()
    end

    test "are used to generate code" do
      assert Payment.diagram() =~ "digraph {"
    end
  end
end

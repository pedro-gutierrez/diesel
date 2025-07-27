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
      assert [:fsm, :action, :next, :on, :state, :states] == Fsm.Dsl.tags()
    end

    test "export their formatter configuration" do
      assert [fsm: :*, action: :*, next: :*, on: :*, state: :*, states: :*] ==
               Fsm.Dsl.locals_without_parens()
    end

    test "produce an internal definition" do
      assert {
               :fsm,
               [name: "payment"],
               [
                 {:state, [name: :pending, timeout: 1],
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
                 {:state, [name: :accepted, timeout: 1], []},
                 {:state, [name: :declined, timeout: 1], []},
                 {:states, [name: [:accepted, :declined]], []}
               ]
             } == Payment.definition()
    end

    test "are used to generate code" do
      assert Payment.diagram() =~ "digraph {"
    end

    test "support default values" do
      transitions = Payment.transitions()

      sent_transitions = Enum.filter(transitions, &(&1.from == :sent))
      non_sent_transitions = Enum.reject(transitions, &(&1.from == :sent))

      refute Enum.empty?(sent_transitions)
      refute Enum.empty?(non_sent_transitions)

      assert Enum.all?(non_sent_transitions, &(&1.timeout == 1))
      assert Enum.all?(sent_transitions, &(&1.timeout == 60))
    end
  end

  test "allows nodes with attributes but without children" do
    assert {:route, [name: "/", method: "get"], []} == Index.definition()
    assert {:route, [name: "/home", method: "get"], []} == Home.definition()
    assert {:route, [name: "/orders", method: "post"], []} == CreateOrder.definition()
  end
end

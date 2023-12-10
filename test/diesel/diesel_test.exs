defmodule DieselTest do
  use ExUnit.Case

  describe "dsls" do
    test "are made of tags" do
      assert [:fsm, :action, :next, :on, :state] == Fsm.Dsl.tags()
    end

    test "export their formatter configuration" do
      assert [fsm: :*, action: :*, next: :*, on: :*, state: :*] == Fsm.Dsl.locals_without_parens()
    end

    test "produce an internal definition" do
      assert {
               :fsm,
               [],
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

    test "can be parsed with utility functions" do
      definition = Payment.definition()

      assert 4 == definition |> Diesel.children(:state) |> length
      assert {:state, [name: :pending], _} = Diesel.child(definition, :state)
      assert [] = Diesel.children(definition, :on)
    end

    test "are used to generate code" do
      assert Payment.diagram() =~ "digraph {"
    end
  end
end

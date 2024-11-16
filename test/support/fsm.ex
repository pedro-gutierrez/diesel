defmodule Fsm.Dsl.Fsm do
  @moduledoc false
  use Diesel.Tag

  tag do
    attribute :name, kind: :string
    child :state, min: 1
  end
end

defmodule Fsm.Dsl.State do
  @moduledoc false
  use Diesel.Tag

  tag do
    attribute :name, kind: :atom, in: [:pending, :sent, :accepted, :declined]
    attribute :timeout, kind: :number, required: false
    child :on, min: 0
  end
end

defmodule Fsm.Dsl.Action do
  @moduledoc false
  use Diesel.Tag

  tag do
    child kind: :module, min: 1, max: 1
  end
end

defmodule Fsm.Dsl.On do
  @moduledoc false
  use Diesel.Tag

  tag do
    attribute :event, kind: :atom
    child :next, min: 1, max: 1
    child :action, min: 0
  end
end

defmodule Fsm.Dsl.Next do
  @moduledoc false
  use Diesel.Tag

  tag do
    attribute :state, kind: :atom, in: [:pending, :sent, :accepted, :declined]
  end
end

defmodule Fsm.Dsl do
  @moduledoc false
  use Diesel.Dsl,
    otp_app: :diesel,
    tags: [
      Fsm.Dsl.Action,
      Fsm.Dsl.Next,
      Fsm.Dsl.On,
      Fsm.Dsl.State
    ]
end

defmodule Transition do
  @moduledoc false
  defstruct [:from, :to, :event, :actions]
end

defmodule Fsm.Parser do
  @moduledoc false
  @behaviour Diesel.Parser

  @impl true
  def parse({:fsm, [], states}, _opts) do
    for {:state, state, events} <- states,
        {:on, event, transition} <- events do
      next_state = next_state(transition)
      actions = actions(transition)

      %Transition{
        from: Keyword.fetch!(state, :name),
        event: Keyword.fetch!(event, :event),
        to: next_state,
        actions: actions
      }
    end
  end

  defp next_state(transition) do
    transition
    |> Enum.find(transition, fn
      {:next, _, _} -> true
      _ -> false
    end)
    |> case do
      nil -> nil
      {:next, attrs, _} -> Keyword.fetch!(attrs, :state)
    end
  end

  defp actions(transition) do
    transition
    |> Enum.reduce([], fn
      {:action, [module: action], _}, acc -> [action | acc]
      _, acc -> acc
    end)
    |> Enum.reverse()
  end
end

defmodule Fsm.Diagram do
  @moduledoc false
  @behaviour Diesel.Generator

  @impl true
  def generate(transitions, _) do
    transitions =
      Enum.map_join(transitions, "\n", fn t ->
        "#{t.from} -> #{t.to} [label=\"#{t.event}\""
      end)

    diagram = """
    digraph {
      #{transitions}
    }
    """

    quote do
      @doc "Returns a diagram of the state machine in Graphviz format"
      def diagram, do: unquote(diagram)
    end
  end
end

defmodule Fsm do
  @moduledoc false
  use Diesel,
    otp_app: :diesel,
    generators: [
      Fsm.Diagram
    ]
end

# Tutorial

In this tutorial, we will go through the process of designing a DSL for a finite state machine. We will
use such state machine to express the lifecycle of a payment.

## A state machine for payments

```elixir
defmodule MyApp.Payments.Payment do
  use MyApp.Fsm

  fsm do
    state :pending do
      on event: :created do
        action SendToGateway
        next state: :sent
      end
    end

    state :sent, timeout: 60 do
      on event: :success do
        action NotifyParties
        next state: :accepted
      end

      on event: :error do
        action NotifyParties
        next state: :declined
      end

      on event: :timeout do
        action NotifyParties
        next state: :declined
      end
    end

    state :accepted do
    end

    state :declined do
    end
  end
end
```

## The Fsm library module

First, lets define the `MyApp.Fsm` library module:

```elixir
defmodule MyApp.Fsm do
  use Diesel,
    otp_app: :my_app,
    dsl: MyApp.Dsm.Dsl
end
```

This module will import the api offered by the actual, which will be defined by a delegate module `MyApp.Fsm.Dsl`.

## Defining the DSL

We will need the following elements of the language:

* `fsm`: the root tag of the dsl
* `state`: a definition of a state
* `action`: an action to be triggered as soon as we enter a state
* `on`: the definition of an event, in a given state
* `next`: the next state to transition into


```elixir
defmodule MyApp.Fsm.Dsl do
  use Diesel.Dsl,
    otp_app: :my_app,
    root: MyApp.Fsm.Dsl.Fsm,
    tags: [
      MyApp.Fsm.Dsl.Action,
      MyApp.Fsm.Dsl.Next,
      MyApp.Fsm.Dsl.On,
      MyApp.Fsm.Dsl.State
    ]
end
```

In the next sections, we will define these as **structured tags** by relying on the `Diesel.Tag` built-in dsl.

#### The fsm root tag

The `fsm` tag is the root of our DSL. It supports one or many `state` children tags:

```elixir
defmodule MyApp.Fsm.Dsl.Fsm do
  use Diesel.Tag

  tag do
    child :state, min: 1
  end
end
```

#### The state tag

The `state` tag requires:

* a `name` attribute (this is the default attribute name in Diesel). The accepted values are:
`pending`, `sent`, `accepted`, `declined`.
* an optional `timeout` attribute
* zero, one or multiple `on` children

```elixir
defmodule MyApp.Fsm.Dsl.State do
  use Diesel.Tag

  tag do
    attribute :name, kind: :atom, one_of: [:pending, :sent, :accepted, :declined]
    attribute :timeout, kind: :number, required: false
    child :on, min: 0
  end
end
```

The `:name` attribute of any given tag is implicit. For example, the following notation:

```elixir
state :pending do
  ...
end
```

is equivalent to:

```elixir
state name: :pending do
  ...
end
```


#### The action tag

The `action` supports the name of an Elixir module as its ony child:

```elixir
defmodule MyApp.Fsm.Dsl.Action do
  use Diesel.Tag

  tag do
    child kind: :module, min: 0
  end
end
```

In other words, when there is a single child involved, the notation

```elixir
action SomeModule
```

is equivalent to:

```elixir
action do
  SomeModule
end
```

#### The on tag

The `on` tag supports:

* the `name` of the event, as an attribute
* exactly one `next` child, as the next state
* zero, one or multiple `action` modules to execute as part of the state transition


```elixir
defmodule MyApp.Fsm.Dsl.On do
  use Diesel.Tag

  tag do
    attribute :event, kind: :atom
    child :next, min: 0, max: 1
    child :action, min: 0
  end
end
```

#### The next tag

The `next` tag only supports the next state to transition to, as the `name` attribute:

```elixir
defmodule MyApp.Fsm.Dsl.Next do
  use Diesel.Tag

  tag do
    attribute :state, kind: :atom, one_of: [:pending, :sent, :accepted, :declined]
  end
end
```

## Parsing the DSL

We can convert the resulting dsl into an alternative representation, for easier consumption during code generation.

For example, if we define a custom `Transition` struct to model state transitions:

```elixir
defmodule MyApp.Fsm.Transition do
  @moduledoc """
  A custom representation of a state transition

  * `from` is the source state
  * `to` is the target state
  * `event` is the triggering event
  * `actions` is a list of Elixir modules to execute as side effects
  """
  defstruct [:from, :to, :event, :actions]
```

then we can define a parser module that transforms the original raw definition (a tree of tuples) into a plain list of `Transition` structrs:

```elixir
defmodule MyApp.Fsm do
  use Diesel,
    otp_app: ...,
    dsl: ...,
    parsers: [
      Fsm.Parser
    ]
end
```

Please check the `Fsm.Parser` module included in `test/support/fsm.ex`.

## Generating code

Once our state machine is parsed into a list of transitions, we can then generate any custom code of our choice and inject it into our `MyApp.Fsm` module.

Generated code is provided by implementations of the `Diesel.Generator` behaviour. For example, in order to generate a `diagram/0` function that returns a Graphviz diagram for our state machine, we could make use of module `Fsm.Diagram`, also included in `test/support/fsm.ex`:

```elixir
defmodule MyApp.Fsm do
  use Diesel,
    otp_app: ...,
    dsl: ...,
    parsers: ...,
    generators: [
      Fsm.Diagram
    ]
end
```

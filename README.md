# Diesel

A toolkit to build DSLs in Elixir

## Installation

The package can be installed by adding `diesel` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:diesel, "~> 0.1.0"}
  ]
end
```
## Description

DSLs built with Diesel are:

* Purely declarative: they look just like HTML
* Extensible: via package modules and generators

## Usage

### Defining a DSL

Here is a very simple dsl that provides with a syntax composed of a `fsm` and a `state` macro:

```elixir
defmodule MyApp.Fsm.Dsl do
  use Diesel.Dsl,
    otp_app: :my_app,
    root: :fsm,
    packages: [
      MyApp.Fsm.Dsl.State
    ]
end
```

where:

```elixir
defmodule MyApp.Fsm.Dsl.State do
  use Diesel.Package, tags: [:state]
end
```

### Compiling a DSL

Once defined, a DSL syntax can be imported into a library module:

```elixir
defmodule MyApp.Fsm do
  use Diesel,
    otp_app: :my_app,
    dsl: Fsm.Dsl,
    generators: [ ... ]
end
```

A list of generator modules can be provided, in order to produce actual Elixir code out of the DSL.
Check the `Diesel.Generator` behaviour for more information on this.

By default, the raw definition defined by the dsl will be given to generators. Such a definition is in the form of a tree of nested tuples, similar to the structure you'd expect from a html document.

It is possible however to add a parsing step in order to convert the raw definition into a more suitable data structure to be consumed by generators. All you need to do is override the `parse/2` function defined by the `Diesel.Parser` behaviour, which is automatically implemented by modules using the `Diesel` macro.

```elixir
defmodule MyApp.Fsm do
  use Diesel
  ...

  defstruct states: []

  @impl Diesel.Parser
  def parse(caller_module, {:fsm, [], states} = raw_definition) do
    ...
    %__MODULE__{states: ...} # this will be given to generators, instead of the raw definition
  end
end
```


### Kernel conflicts

Depending on how you define your DSL, you might get compiler errors in the form `function /Y
imported from both (YOUR DSL) and Kernel, call is ambiguous`.

You can stop importing the one from Kernel via the `:overrides` key, eg:

```elixir
defmodule MyApp.Html do
  use Diesel,
    otp_app: :my_app,
    dsl: MyApp.Html.Dsl,
    overrides: [div: 1]
```

### Compilation flags

Compilation flags allow you to customise the definition before it goes to the actual compilation phase:

```elixir
defmodule MyApp.Latex do
  use Diesel,
    otp_app: :my_app,
    dsl: MyApp.Latex.Dsl,
    compilation_flags: [:strip_root]
```

Supported flags:

* `strip_root`: before compiling, strip the root element from the definition.

### Using a DSL

The `Fsm` library module from the example above is now ready to be used:

```elixir
defmodule MyApp.Payment do
  use MyApp.Fsm

  fsm do
    state name: :pending do
      ...
    end

    state name: :accepted do
      ...
    end

    state name: :declined do
      ...
    end
  end
end
```

The `:name` attribute of any given tag is implicit. For example, the following notation:

```elixir
state :pending, final: true do
  ...
end
```

is equivalent to:

```elixir
state name: :pending, final: true do
  ...
end
```

### Extending a DSL

DSLs made with Diesel are not closed. Once defined, they can still be extended by application
developers, via application environment configuration:

```elixir
config :my_app, MyApp.Fsm.Dsl, packages: [ ...]
config :my_app, MyApp.Fsm, generators: [ ... ]
```

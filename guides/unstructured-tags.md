# Unstructured tags

In general, it is highly recommended to express DSLs in terms of structured tags, by using the
`Diesel.Tag` macro. This will enforce a well defined schema and the compiler will be able to pick up
misconfigurations and/or omissions and raise errors early.

This said, it is also possible to express a DSL in terms of unstructured, or plain atom tags, when
more informal definitions might be acceptable:

```elixir
defmodule MyApp.Html.Dsl do
  use Diesel.Dsl,
    otp_app: :my_app,
    root: :html,
    tags: [:head, :body, :meta, :script, ...]
end
```

## Kernel conflicts

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

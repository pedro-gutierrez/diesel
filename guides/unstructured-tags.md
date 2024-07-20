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

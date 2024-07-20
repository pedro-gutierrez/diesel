# Kernel conflicts

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

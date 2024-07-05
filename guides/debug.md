# Debug

You can turn debug on, in order to see the code being generated by Diesel at compile time.

```elixir
defmodule MyApp.MyFsm do
  use Diesel, debug: true
  ...
end
```
defmodule Diesel.Generator do
  @moduledoc """
  Generators produce actual Elixir code from DSLs.

  Given a definition, a generator returns one or multiple quoted expressions.

  The following info are passed in the keyword list of options:

  - `:otp_app`
  - `:caller_module`
  """
  @callback generate(definition :: term(), opts :: Keyword.t()) :: Macro.t() | [Macro.t()]
end

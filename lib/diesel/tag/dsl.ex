defmodule Diesel.Tag.Dsl do
  @moduledoc """
  The meta-dsl that allow developers to design structured tags
  """
  use Diesel.Dsl,
    otp_app: :diesel,
    root: :tag,
    tags: [:attribute, :child]
end

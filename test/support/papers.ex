defmodule Papers do
  @moduledoc false
  use Latex

  latex do
    document :essai, status: :draft do
    end

    document name: :thesis do
    end
  end
end

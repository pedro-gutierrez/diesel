defmodule Latex.Dsl.Preamble do
  use Diesel.Block,
    tags: [
      :document,
      :package
    ]
end

defmodule Latex.Dsl.Content do
  use Diesel.Block,
    tags: [
      :section,
      :subsection
    ]
end

defmodule Latex.Dsl.Music do
  use Diesel.Block,
    tags: [
      :music,
      :instrument,
      :meter
    ]
end

defmodule Latex.Dsl do
  use Diesel,
    otp_app: :diesel,
    root: :latex,
    blocks: [
      Latex.Dsl.Preamble,
      Latex.Dsl.Content
    ]
end

defmodule Latex do
  defmacro __using__(_) do
    quote do
      @dsl Latex.Dsl
      import Latex.Dsl
      @before_compile Latex
    end
  end

  defmacro __before_compile__(_env) do
  end
end

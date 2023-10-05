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
  use Diesel.Dsl,
    otp_app: :diesel,
    root: :latex,
    blocks: [
      Latex.Dsl.Preamble,
      Latex.Dsl.Content
    ]
end

defmodule Latex.Pdf do
  @behaviour Diesel.Generator

  @impl true
  def generate(_mod, _definition) do
    quote do
      def pdf, do: "%PDF-1.4 ..."
    end
  end
end

defmodule Latex.Html do
  @behaviour Diesel.Generator

  @impl true
  def generate(_mod, _definition) do
    quote do
      def html, do: "<html> ..."
    end
  end
end

defmodule Latex do
  use Diesel,
    otp_app: :diesel,
    dsl: Latex.Dsl,
    generators: [
      Latex.Pdf
    ]
end

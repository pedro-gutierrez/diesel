defmodule Latex.Dsl.Content do
  @moduledoc false
  use Diesel.Package,
    tags: [
      :section,
      :subsection
    ]

  @impl true
  def compiler do
    quote do
      def compile({:section, attrs, children}, ctx) do
        attrs = attrs |> Keyword.put_new(:numbered, true) |> compile(ctx)
        children = compile(children, ctx)

        {:section, attrs, children}
      end
    end
  end
end

defmodule Latex.Dsl.Music do
  @moduledoc false
  use Diesel.Package,
    tags: [
      :music,
      :instrument,
      :meter
    ]
end

defmodule Latex.Dsl do
  @moduledoc false
  use Diesel.Dsl,
    otp_app: :diesel,
    root: :latex,
    tags: [:document, :package, :packages],
    packages: [
      Latex.Dsl.Content
    ]

  @impl Diesel.Dsl
  def compile({:packages, names, _}, _ctx) do
    for name <- names, do: {:package, [name: name], []}
  end
end

defmodule Latex.Pdf do
  @moduledoc false
  @behaviour Diesel.Generator

  @impl true
  def generate(_mod, _definition) do
    quote do
      def pdf, do: "%PDF-1.4 ..."
    end
  end
end

defmodule Latex.Html do
  @moduledoc false
  @behaviour Diesel.Generator

  @impl true
  def generate(_mod, _definition) do
    quote do
      def html, do: "<html> ..."
    end
  end
end

defmodule Latex do
  @moduledoc false
  use Diesel,
    otp_app: :diesel,
    dsl: Latex.Dsl,
    generators: [
      Latex.Pdf
    ]
end

defmodule Diesel.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :diesel,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: [
        maintainers: [
          "Pedro Gutiérrez"
        ],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/pedro-gutierrez/diesel"},
        files: ~w(lib mix.exs .formatter.exs LICENSE.md README.md),
        description: "Declarative programming in Elixir"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths do
    case Mix.env() do
      :test -> ["lib", "test/support"]
      _env -> ["lib"]
    end
  end

  defp deps do
    [
      {:credo, "~> 1.7"},
      {:ex_doc, ">= 0.0.0"},
      {:solid, "~> 0.15"}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      formatters: ["html", "epub"]
    ]
  end
end

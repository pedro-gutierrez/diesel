defmodule Diesel.MixProject do
  use Mix.Project

  @version "0.8.3"

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
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: extras(),
      formatters: ["html", "epub"],
      source_ref: "v#{@version}"
    ]
  end

  defp extras do
    [
      "guides/overview.md",
      "guides/installation.md",
      "guides/tutorial.md",
      "guides/parsers.md",
      "guides/generators.md",
      "guides/unstructured-tags.md",
      "guides/kernel-conflicts.md",
      "guides/debug.md"
    ]
  end
end

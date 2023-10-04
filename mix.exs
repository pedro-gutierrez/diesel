defmodule Diesel.MixProject do
  use Mix.Project

  def project do
    [
      app: :diesel,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
    []
  end
end

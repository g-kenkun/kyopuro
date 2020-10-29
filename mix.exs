defmodule Kyopuro.MixProject do
  use Mix.Project

  def project do
    [
      app: :kyopuro,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Kyopuro.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.5.1"},
      {:meeseeks, "~> 0.15.1"}
    ]
  end
end

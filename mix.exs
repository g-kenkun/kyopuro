defmodule Kyopuro.MixProject do
  use Mix.Project

  def project do
    [
      app: :kyopuro,
      version: "0.2.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Kyopuro",
      source_url: "https://github.com/g-kenkun/kyopuro",
      homepage_url: "https://github.com/g-kenkun/kyopuro",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eex],
      mod: {Kyopuro.Application, []}
    ]
  end

  defp description do
    """
    This package provides a mix of tasks for AtCoder. This package provides mix tasks for module generation and test case generation.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/g-kenkun/kyopuro"}
    ]
  end

  defp deps do
    [
      {:finch, "~> 0.5.2"},
      {:meeseeks, "~> 0.15.1"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end

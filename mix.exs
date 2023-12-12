defmodule Kyopuro.MixProject do
  use Mix.Project

  def project do
    [
      app: :kyopuro,
      version: "0.6.0",
      elixir: "~> 1.15.2",
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
      extra_applications: [:logger, :eex]
    ]
  end

  defp description do
    """
    This package provides mix tasks for AtCoder.
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
      # Util
      {:unicode, "~> 1.18"},

      # For processing
      {:floki, "~> 0.35.2"},
      {:httpoison, "~> 2.2"},

      # For prompt
      {:owl, "~> 0.8.0"},

      # For ExDoc
      {:ex_doc, "~> 0.31.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end

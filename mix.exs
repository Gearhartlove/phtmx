defmodule Phtmx.MixProject do
  use Mix.Project

  @version "0.2.2"
  @source_url "https://github.com/Gearhartlove/phtmx"

  def project do
    [
      app: :phtmx,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Phtmx",
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:jason, "~> 1.2"},
      # Install-time only: powers `mix phtmx.install`. Optional so it stays out
      # of consumers' runtime dependency closure.
      {:igniter, "~> 0.8", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    "A tiny, convention-over-configuration HTMX integration for Phoenix."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md .formatter.exs)
    ]
  end

  defp docs do
    [
      main: "Phtmx",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end

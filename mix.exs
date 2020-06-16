defmodule CQEx.Mixfile do
  @moduledoc false

  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :cqex,
      version: @version,
      elixir: "~> 1.0",
      description: description(),
      package: package(),
      source_url: "https://github.com/cqerl/cqex",
      deps: deps(),
      docs: [
        extras: ["README.md"],
        main: "README",
        source_ref: "v#{@version}",
        source_url: "https://github.com/cqerl/cqex"
      ]
    ]
  end

  def application do
    [applications: [:cqerl]]
  end

  defp deps do
    [
      {:cqerl, "~> 2.0.1"},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Idiomatic Elixir client for Cassandra.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Mathieu D'Amours"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/cqerl/cqex"}
    ]
  end
end

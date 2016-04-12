defmodule CQEx.Mixfile do
  use Mix.Project

  @version "0.1.5"

  def project do
    [app: :cqex,
     version: @version,
     elixir: "~> 1.0",
     description: description,
     package: package,
     source_url: "https://github.com/matehat/cqex",
     deps: deps,
     docs: [extras: ["README.md"], main: "README",
            source_ref: "v#{@version}",
            source_url: "https://github.com/matehat/cqex"]]
  end

  def application do
    [applications: [:cqerl]]
  end

  defp deps do
    [{ :cqerl, github: "matehat/cqerl", tag: "v0.10.0" }]
  end

  defp description do
    """
    Idiomatic Elixir client for Cassandra.
    """
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Mathieu D'Amours"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/matehat/cqex"}]
  end
end

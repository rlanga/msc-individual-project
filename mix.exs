defmodule Chord.MixProject do
  use Mix.Project

  def project do
    [
      app: :chord,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
      #      mod: {Chord, }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:jsonrpc2, "~> 2.0"},
      {:jason, "~> 1.2.1"},
      #      {:shackle, "~> 0.5.4"},
      #      {:ranch, "~> 1.7"}
      {:plug, "~> 1.10"},
      {:cowboy, "~> 2.8"},
      {:plug_cowboy, "~> 2.3"},
      {:hackney, "~> 1.16"}
      #      {:logger_file_backend, "~> 0.0.11"}
    ]
  end
end

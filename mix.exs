defmodule Glot.MixProject do
  use Mix.Project

  def project do
    [
      app: :glot,
      version: "0.1.2",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_paths: ["test", "lib"],
      test_pattern: "*_test.exs",
      # Hex
      description:
        "A minimalistic translation system for Elixir applications using JSONL glossaries",
      package: package(),
      # Docs
      name: "Glot",
      source_url: "https://github.com/maxohq/glot",
      homepage_url: "https://github.com/maxohq/glot",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Glot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:file_system, "~> 1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Maxo"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/maxohq/glot"},
      files: ~w(lib mix.exs README.md LICENSE),
      exclude_patterns: ~w(test/ _build/ deps/ .git/ .elixir_ls/ .DS_Store)
    ]
  end
end

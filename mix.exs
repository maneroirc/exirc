defmodule ExIRC.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exirc,
      version: "2.0.0",
      elixir: "~> 1.6",
      description: "An IRC client library for Elixir.",
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.post": :test
      ],
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  def application do
    [mod: {ExIRC.App, []}, applications: [:ssl, :crypto, :inets]]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md"],
      maintainers: ["Graham McIntire", "Paul Schoenfelder", "Théophile Choutri"],
      licenses: ["MIT"]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :dev},
      {:excoveralls, "~> 0.13", only: :test},
      {:styler, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end
end

defmodule Magnolia.MixProject do
  use Mix.Project

  def project do
    [
      app: :magnolia,
      version: "0.7.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [
        main_module: Magnolia
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rational, git: "https://github.com/q60/rational", tag: "1.2.0"}
    ]
  end
end

defmodule Beetle.Mixfile do
  use Mix.Project

  def project do
    [
      app: :beetle,
      description: "A rate-limiter with plugable backends.",
      package: [
        name: :beetle,
        maintainers: ["Ihor Katkov (ihorkatkov@gmail.com)"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/ihorkatkov/beetle"}
      ],
      source_url: "https://github.com/ihorkatkov/beetle",
      homepage_url: "https://github.com/ihorkatkov/beetle",
      version: "1.0.0",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: dialyzer(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poolboy, "~> 1.5"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.5", only: :test},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end
end

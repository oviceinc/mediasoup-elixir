defmodule MediasoupElixir.MixProject do
  use Mix.Project

  @version "0.7.4"
  @repo "https://github.com/oviceinc/mediasoup-elixir"
  @description """
  Elixir wrapper for mediasoup
  """

  def project do
    [
      app: :mediasoup_elixir,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        dialyzer: :test,
        "coveralls.detail": :test,
        "coveralls.lcov": :test,
        "coveralls.github": :test
      ],
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit, :rustler],
        check_plt: true
      ],
      name: "mediasoup_elixir",
      description: @description,
      package: package(),
      source_url: @repo,
      homepage_url: @repo
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
      {:rustler, ">= 0.0.0", optional: true},
      {:rustler_precompiled, "~> 0.7"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18.0", only: :test},
      {:local_cluster, "~> 1.2", only: :test},
      # global_flags used in local_cluster
      {:global_flags, "~> 1.0", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "mediasoup_elixir",
      maintainers: ["ovice"],
      licenses: ["ISC"],
      links: %{"Github" => @repo},
      files: [
        "lib",
        "native",
        "README.md",
        "checksum-*.exs",
        "mix.exs"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/integration"]
  defp elixirc_paths(:dialyzer), do: ["lib", "test/integration"]
  defp elixirc_paths(_), do: ["lib"]
end

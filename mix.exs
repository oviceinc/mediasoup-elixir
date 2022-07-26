defmodule MediasoupElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :mediasoup_elixir,
      version: "0.4.2",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        dialyzer: :dialyzer,
        "coveralls.detail": :test,
        "coveralls.lcov": :test,
        "coveralls.github": :test
      ],
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        check_plt: true
      ],
      # Docs
      name: "mediasoup_elixir",
      source_url: "https://github.com/oviceinc/mediasoup-elixir",
      homepage_url: "https://github.com/oviceinc/mediasoup-elixir",
      docs: [
        # The main page in the docs
        main: "mediasoup_elixir",
        extras: ["README.md"]
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
      {:rustler, "~> 0.23.0"},
      {:dialyxir, "~> 1.0", only: :dialyzer, runtime: false},
      {:excoveralls, "~> 0.14.2", only: :test},
      {:local_cluster, "~> 1.2", only: :test},
      # global_flags used in local_cluster
      {:global_flags, "~> 1.0", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/integration"]
  defp elixirc_paths(:dialyzer), do: ["lib", "test/integration"]
  defp elixirc_paths(_), do: ["lib"]
end

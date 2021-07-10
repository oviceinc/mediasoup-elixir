defmodule MediasoupElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :mediasoup_elixir,
      version: "0.0.1",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      rustler_crates: rustler_crates(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [
        tool: LcovEx,
        output: "coverage",
        ignore_paths: ["test/"]
      ],
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        check_plt: true
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
      # We'are waiting for new release of rustler.
      # It must contains https://github.com/rusterlium/rustler/pull/361
      # Because nif symlink is not created at first compile: https://github.com/oviceinc/mediasoup-elixir/issues/10
      {:rustler, "~> 0.22.0"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:lcov_ex, "~> 0.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp rustler_crates() do
    [
      mediasoup: [
        path: "native/mediasoup_elixir",
        mode: if(Mix.env() == :prod, do: :release, else: :debug)
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/integration"]
  defp elixirc_paths(_), do: ["lib"]
end

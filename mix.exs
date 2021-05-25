defmodule MediasoupElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :mediasoup_elixir,
      version: "0.0.1",
      elixir: "~> 1.7",
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: rustler_crates(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:rustler, "~> 0.22.0-rc.1"}
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
end

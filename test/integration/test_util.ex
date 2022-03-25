defmodule Mediasoup.TestUtil do
  import ExUnit.Assertions

  def worker_leak_setup_all(_context \\ %{}) do
    with_leakcheck =
      ExUnit.configuration() |> Keyword.fetch!(:include) |> Enum.member?(:leakcheck)

    if with_leakcheck do
      Registry.start_link(keys: :unique, name: Mediasoup.Worker.Registry)

      ExUnit.Callbacks.on_exit(fn ->
        ref = Process.monitor(Mediasoup.Worker.Registry)
        assert_receive {:DOWN, ^ref, _, _, _}, 1000
      end)
    end

    :ok
  end

  def verify_worker_leak_on_exit!(_context \\ %{}) do
    with_leakcheck =
      ExUnit.configuration() |> Keyword.fetch!(:include) |> Enum.member?(:leakcheck)

    if with_leakcheck do
      ExUnit.Callbacks.on_exit(fn ->
        for {pid, _value} <- Registry.lookup(Mediasoup.Worker.Registry, :id) do
          ref = Process.monitor(pid)
          assert_receive {:DOWN, ^ref, _, _, _}, 1000
        end

        assert Mediasoup.Worker.worker_count() === 0
        assert os_thread_count_by_name("mediasoup-task") === 0
      end)
    end

    :ok
  end

  def os_thread_count_by_name(name) do
    {c, _status} =
      case :os.type() do
        {:unix, :linux} -> System.shell("ps -T -p #{:os.getpid()} | grep #{name} | wc -l")
        _ -> {"0", :not_supported}
      end

    c
    |> String.trim()
    |> String.to_integer()
  end
end

defmodule WorkerTest do
  use ExUnit.Case
  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  test "create_worker_with_default_settings" do
    IntegrateTest.WorkerTest.create_worker_with_default_settings()
  end

  test "worker_with_custom_settings" do
    IntegrateTest.WorkerTest.worker_with_custom_settings()
  end

  test "create_worker_with_struct" do
    IntegrateTest.WorkerTest.create_worker_with_struct()
  end

  test "worker with wrong settings cert" do
    IntegrateTest.WorkerTest.worker_with_wrong_settings_cert()
  end

  test "worker_with_wrong_settings_port" do
    IntegrateTest.WorkerTest.worker_with_wrong_settings_port()
  end

  test "update_settings_succeeds" do
    IntegrateTest.WorkerTest.update_settings_succeeds()
  end

  test "dump_succeeds" do
    IntegrateTest.WorkerTest.dump_succeeds()
  end

  test "close_event" do
    IntegrateTest.WorkerTest.close_event()
  end

  test "close_router" do
    IntegrateTest.WorkerTest.close_router()
  end

  test "create_many_worker" do
    IntegrateTest.WorkerTest.create_many_worker()
  end

  @tag :leakcheck
  test "worker leak check" do
    {:ok, worker} = Mediasoup.Worker.start_link()
    Mediasoup.Worker.close(worker)
    Process.sleep(1)
    assert Mediasoup.Worker.worker_count() === 0
  end

  @tag :leakcheck
  test "worker leak check concurrency" do
    1..100
    |> Task.async_stream(
      fn _ ->
        {:ok, worker} = Mediasoup.Worker.start_link()
        Mediasoup.Worker.close(worker)
      end,
      max_concurrency: 8,
      timeout: 10_000
    )

    Process.sleep(1)
    assert Mediasoup.Worker.worker_count() === 0
  end

  test "register to registry" do
    Registry.start_link(keys: :unique, name: Mediasoup.Worker.Registry)

    {:ok, worker} = Mediasoup.Worker.start_link()

    assert 1 <= Registry.lookup(Mediasoup.Worker.Registry, :id) |> Enum.count()

    Mediasoup.Worker.close(worker)
  end
end

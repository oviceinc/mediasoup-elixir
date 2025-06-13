defmodule WorkerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  setup do
    Mediasoup.LoggerProxy.start_link(max_level: :info)
    %{}
  end

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

  test "close_event_with_dead_target" do
    IntegrateTest.WorkerTest.close_event_with_dead_target()
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

  test "id/1 returns the correct id" do
    {:ok, worker} = Mediasoup.Worker.start_link()
    id = Mediasoup.Worker.id(worker)
    assert is_binary(id)
    assert String.length(id) > 0
    Mediasoup.Worker.close(worker)
  end

  test "closed?/1 returns correct status" do
    {:ok, worker} = Mediasoup.Worker.start_link()
    assert Mediasoup.Worker.closed?(worker) == false
    Mediasoup.Worker.close(worker)
    assert Mediasoup.Worker.closed?(worker) == true
  end

  test "worker_count/0 returns count" do
    initial_count = Mediasoup.Worker.worker_count()
    {:ok, worker} = Mediasoup.Worker.start_link()
    assert Mediasoup.Worker.worker_count() == initial_count + 1
    Mediasoup.Worker.close(worker)
    # Wait for worker to close
    Process.sleep(10)
    assert Mediasoup.Worker.worker_count() == initial_count
  end

  test "event/3 registers event listener" do
    {:ok, worker} = Mediasoup.Worker.start_link()
    assert :ok = Mediasoup.Worker.event(worker, self(), [:on_close])
    Mediasoup.Worker.close(worker)
    assert_receive {:on_close}
  end

  test "Cover Worker terminate/2 (including on_dead event)" do
    {:ok, worker} = Mediasoup.Worker.start_link()
    Process.unlink(worker)
    ref = Process.monitor(worker)
    # Send on_dead event directly
    capture_log(fn ->
      send(worker, {:nif_internal_event, :on_dead, "test_message"})
      # Wait for the process to stop and receive the DOWN message
      assert_receive {:DOWN, ^ref, :process, ^worker, :shutdown}, 1000
      # Do not call GenServer.stop(pid) here, as the process is already dead
      # Also cover normal terminate
    end)
  end

  test "Cover Worker terminate/2 (including on_close event)" do
    {:ok, worker} = Mediasoup.Worker.start_link()
    Process.unlink(worker)
    ref = Process.monitor(worker)
    # Send on_dead event directly
    capture_log(fn ->
      send(worker, {:nif_internal_event, :on_close})
      # Wait for the process to stop and receive the DOWN message
      assert_receive {:DOWN, ^ref, :process, ^worker, :normal}, 1000
      # Do not call GenServer.stop(pid) here, as the process is already dead
      # Also cover normal terminate
    end)
  end
end

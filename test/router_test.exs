defmodule RouterTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  setup do
    settings = %{
      rtcMinPort: 10000,
      rtcMaxPort: 10010,
      logLevel: :error
    }

    {:ok, worker} = Mediasoup.Worker.start_link(settings: settings)

    %{worker: worker}
  end

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  test "create_router_succeeds", %{worker: worker} do
    IntegrateTest.RouterTest.create_router_succeeds(worker)
  end

  test "router_dump", %{worker: worker} do
    IntegrateTest.RouterTest.router_dump(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.RouterTest.close_event(worker)
  end

  test "close_worker", %{worker: worker} do
    IntegrateTest.RouterTest.close_worker(worker)
  end

  test "do not crash when badarg", %{worker: worker} do
    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %Mediasoup.Router.Options{
        media_codecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    assert_raise ArgumentError, fn ->
      Mediasoup.Router.can_consume?(router, {:badarg}, %{})
    end
  end

  test "id/1 returns the correct id", %{worker: worker} do
    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    assert Mediasoup.Router.id(router) == router.id

    GenServer.stop(router.pid)
    if Process.alive?(router.pid), do: Mediasoup.Router.close(router)
  end

  test "closed?/1 returns correct status", %{worker: worker} do
    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    assert Mediasoup.Router.closed?(router) == false
    GenServer.stop(router.pid)
    if Process.alive?(router.pid), do: Mediasoup.Router.close(router)
    assert Mediasoup.Router.closed?(router) == true
  end

  test "struct_from_pid/1 returns the correct struct", %{worker: worker} do
    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    struct = Mediasoup.Router.struct_from_pid(router.pid)
    assert struct.id == router.id

    GenServer.stop(router.pid)
    if Process.alive?(router.pid), do: Mediasoup.Router.close(router)
  end

  test "event/3 registers event listener", %{worker: worker} do
    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    assert :ok = Mediasoup.Router.event(router, self(), [:on_close])

    GenServer.stop(router.pid)
    if Process.alive?(router.pid), do: Mediasoup.Router.close(router)
    assert_receive {:on_close}
  end

  test "rtp_capabilities/1 returns capabilities", %{worker: worker} do
    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    capabilities = Mediasoup.Router.rtp_capabilities(router)
    assert is_map(capabilities)
    assert Map.has_key?(capabilities, "codecs")

    GenServer.stop(router.pid)
    if Process.alive?(router.pid), do: Mediasoup.Router.close(router)
  end

  test "dump/1 returns internal state", %{worker: worker} do
    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    dump = Mediasoup.Router.dump(router)
    assert is_map(dump)
    assert Map.has_key?(dump, "id")

    GenServer.stop(router.pid)
    if Process.alive?(router.pid), do: Mediasoup.Router.close(router)
  end

  test "pipe_data_producer_to_router/3 works (basic call test)", %{worker: worker} do
    {:ok, router1} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    {:ok, router2} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    # Use dummy IDs for DataProducer/DataConsumer
    options = %Mediasoup.Router.PipeToRouterOptions{router: router2}
    # data_producer_id is also dummy
    result =
      Mediasoup.Router.pipe_data_producer_to_router(router1, "dummy_data_producer_id", options)

    # Just check that the call does not raise an exception, even if it fails
    assert match?({:ok, _}, result) or match?({:error, _}, result)
    GenServer.stop(router1.pid)
    if Process.alive?(router1.pid), do: Mediasoup.Router.close(router1)
    GenServer.stop(router2.pid)
    if Process.alive?(router2.pid), do: Mediasoup.Router.close(router2)
  end

  test "Directly call GenServer callbacks :get_pipe_transport_pair, :put_pipe_transport_pair",
       %{worker: worker} do
    # Create a Router to get the reference
    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    %{pid: pid} = router
    # :put_pipe_transport_pair
    assert GenServer.call(pid, {:put_pipe_transport_pair, "dummy_id", %{a: 1}}) == :ok
    # :get_pipe_transport_pair returns the pair itself
    assert GenServer.call(pid, {:get_pipe_transport_pair, "dummy_id"}) == %{a: 1}

    GenServer.stop(pid)
    if Process.alive?(pid), do: Mediasoup.Router.close(router)
  end

  test "Cover Router terminate/2 (including on_dead event)", %{worker: worker} do
    Process.flag(:trap_exit, true)

    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    %{pid: pid} = router
    ref = Process.monitor(pid)
    # Send on_dead event directly
    capture_log(fn ->
      send(pid, {:nif_internal_event, :on_dead, "test_message"})
      # Wait for the process to stop and receive the DOWN message
      assert_receive {:DOWN, ^ref, :process, ^pid, :shutdown}, 1000
      # Do not call GenServer.stop(pid) here, as the process is already dead
      # Also cover normal terminate
    end)
  end

  test "Cover Router terminate/2 (including on_close event)", %{worker: worker} do
    Process.flag(:trap_exit, true)

    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: [
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        ]
      })

    %{pid: pid} = router
    ref = Process.monitor(pid)
    # Send on_dead event directly
    capture_log(fn ->
      send(pid, {:nif_internal_event, :on_close})
      # Wait for the process to stop and receive the DOWN message
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 1000
      # Do not call GenServer.stop(pid) here, as the process is already dead
      # Also cover normal terminate
    end)
  end
end

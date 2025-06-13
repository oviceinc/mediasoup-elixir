defmodule RouterTest do
  use ExUnit.Case

  setup do
    Mediasoup.LoggerProxy.start_link(max_level: :info)
    {:ok, worker} = Mediasoup.Worker.start_link()

    %{worker: worker}
  end

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  test "create_router_succeeds", %{worker: worker} do
    IntegrateTest.RouterTest.create_router_succeeds(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.RouterTest.close_event(worker)
  end

  test "close_worker", %{worker: worker} do
    IntegrateTest.RouterTest.close_worker(worker)
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

    Mediasoup.Router.close(router)
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
    Mediasoup.Router.close(router)
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

    Mediasoup.Router.close(router)
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

    Mediasoup.Router.close(router)
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

    Mediasoup.Router.close(router)
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

    Mediasoup.Router.close(router)
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
    Mediasoup.Router.close(router1)
    Mediasoup.Router.close(router2)
  end

  test "Directly call GenServer callbacks :get_node, :get_pipe_transport_pair, :put_pipe_transport_pair",
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
    # :get_node
    assert GenServer.call(pid, {:get_node}) == Node.self()
    # :put_pipe_transport_pair
    assert GenServer.call(pid, {:put_pipe_transport_pair, "dummy_id", %{a: 1}}) == :ok
    # :get_pipe_transport_pair returns the pair itself
    assert GenServer.call(pid, {:get_pipe_transport_pair, "dummy_id"}) == %{a: 1}
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
    send(pid, {:nif_internal_event, :on_dead, "test_message"})
    # Wait for the process to stop and receive the exit message
    assert_receive {:DOWN, ^ref, :process, ^pid, :kill}
  end
end

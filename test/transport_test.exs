defmodule TransportTest do
  use ExUnit.Case

  setup do
    Mediasoup.LoggerProxy.start_link(max_level: :info)
    {:ok, worker} = Mediasoup.Worker.start_link()

    %{worker: worker}
  end

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

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

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %{
        listenIps: [%{ip: "127.0.0.1"}]
      })

    assert Mediasoup.Transport.id(transport) == transport.id

    Mediasoup.Transport.close(transport)
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

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %{
        listenIps: [%{ip: "127.0.0.1"}]
      })

    assert Mediasoup.Transport.closed?(transport) == false
    Mediasoup.Transport.close(transport)
    assert Mediasoup.Transport.closed?(transport) == true

    Mediasoup.Router.close(router)
  end

  test "event/2 registers event listener", %{worker: worker} do
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

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %{
        listenIps: [%{ip: "127.0.0.1"}]
      })

    assert {:ok} = Mediasoup.Transport.event(transport, self())

    Mediasoup.Transport.close(transport)
    assert_receive {:on_close}

    Mediasoup.Router.close(router)
  end
end

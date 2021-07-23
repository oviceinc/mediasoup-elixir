defmodule IntegrateTest.RouterTest do
  import ExUnit.Assertions

  def create_router_succeeds() do
    {:ok, worker} =
      Mediasoup.create_worker(%{
        rtcMinPort: 10000,
        rtcMaxPort: 10010,
        logLevel: :debug
      })

    Mediasoup.Worker.event(worker, self())

    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: {
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          }
        }
      })

    assert true == is_binary(router.id)
  end

  def router_dump() do
    {:ok, worker} =
      Mediasoup.create_worker(%{
        rtcMinPort: 10000,
        rtcMaxPort: 10010,
        logLevel: :debug
      })

    mediaCodecs = [
      %{
        kind: "audio",
        mimeType: "audio/opus",
        clockRate: 48000,
        channels: 2,
        parameters: %{},
        rtcpFeedback: []
      },
      %{
        kind: "video",
        mimeType: "video/VP8",
        clockRate: 90000,
        parameters: %{
          "x-google-start-bitrate": 1000
        },
        rtcpFeedback: []
      }
    ]

    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: mediaCodecs
      })

    assert true == is_binary(router.id)

    [capabilitycodec | _remain] = Mediasoup.Router.rtp_capabilities(router)["codecs"]

    assert match?(
             %{
               "channels" => 2,
               "clockRate" => 48000,
               "kind" => "audio",
               "mimeType" => "audio/opus"
             },
             capabilitycodec
           )

    assert match?(%{"rtpObserverIds" => [], "transportIds" => []}, Mediasoup.Router.dump(router))
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end

  def close_event() do
    {:ok, worker} =
      Mediasoup.create_worker(%{
        rtcMinPort: 10000,
        rtcMaxPort: 10010,
        logLevel: :debug
      })

    {:ok, router} =
      Mediasoup.Worker.create_router(worker, %{
        mediaCodecs: {
          %{
            kind: "audio",
            mimeType: "audio/opus",
            clockRate: 48000,
            channels: 2,
            parameters: %{},
            rtcpFeedback: []
          },
          %{
            kind: "video",
            mimeType: "video/VP8",
            clockRate: 90000,
            parameters: %{
              "x-google-start-bitrate": 1000
            },
            rtcpFeedback: []
          }
        }
      })

    Mediasoup.Router.event(router, self())
    Mediasoup.Router.close(router)
    assert_receive {:on_close}
  end
end

defmodule IntegrateTest.RouterTest do
  @moduledoc """
  test for Router with dializer check
  """
  import ExUnit.Assertions

  def create_router_succeeds(worker) do
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

  def router_dump(worker) do
    media_codecs = [
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
        mediaCodecs: media_codecs
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

  def close_event(worker) do
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

  def close_worker(worker) do
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

    refute Mediasoup.Router.closed?(router)

    Mediasoup.Router.event(router, self())
    Mediasoup.Worker.close(worker)

    assert Mediasoup.Router.closed?(router)
  end
end

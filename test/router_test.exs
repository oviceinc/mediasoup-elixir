defmodule RouterTest do
  use ExUnit.Case

  test "create router succeeds" do
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

    assert is_binary(router.id)
  end

  test "router dump" do
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

    assert is_binary(router.id)

    assert %{"rtpObserverIds" => [], "transportIds" => []} = Mediasoup.Router.dump(router)
  end
end

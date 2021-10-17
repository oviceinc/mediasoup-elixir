defmodule IntegrateTest.SmokeTest do
  @moduledoc """
  Smoke test with dializer check
  """
  def smoke() do
    {:ok, worker} = Mediasoup.Worker.start_link()

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

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %{
        listenIps: {
          %{
            ip: "127.0.0.1"
          }
        },
        enableSctp: true
      })

    {:ok, producer} =
      Mediasoup.WebRtcTransport.produce(transport, %{
        kind: "audio",
        rtpParameters: %{
          mid: "AUDIO",
          codecs:
            {%{
               mimeType: "audio/opus",
               payloadType: 111,
               clockRate: 48000,
               channels: 2,
               parameters: %{},
               rtcpFeedback: []
             }},
          headerExtensions: [],
          encodings: [],
          rtcp: %{
            reducedSize: true
          }
        }
      })

    Mediasoup.WebRtcTransport.consume(transport, %{
      producerId: producer.id,
      rtpCapabilities: %{
        codecs:
          {%{
             kind: "audio",
             mimeType: "audio/opus",
             clockRate: 48000,
             channels: 2,
             parameters: %{},
             rtcpFeedback: []
           }},
        headerExtensions: {},
        fecMechanisms: {}
      }
    })

    Mediasoup.WebRtcTransport.close(transport)
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end
end

defmodule IntegrateTest.SmokeTest do
  import ExUnit.Assertions

  def smoke() do
    {:ok, worker} = Mediasoup.create_worker()

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
  end
end

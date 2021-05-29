defmodule IntegrateTest.WebRtcTransportTest do
  import ExUnit.Assertions

  def webrtc_transport_test2() do
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

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %{
        listenIps: {
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1"
          },
          %{
            ip: "0.0.0.0",
            announcedIp: "9.9.9.2"
          },
          %{
            ip: "127.0.0.1"
          }
        },
        enableTcp: true,
        preferUdp: true,
        enableSctp: true,
        numSctpStreams: %{
          OS: 2048,
          MIS: 2048
        },
        maxSctpMessageSize: 1_000_000
      })

    assert is_binary(transport.id) == true

    ice_candidates = Mediasoup.WebRtcTransport.ice_candidates(transport)

    assert match?(
             [
               %{
                 "foundation" => "udpcandidate",
                 "ip" => "9.9.9.1",
                 "protocol" => "udp",
                 "tcpType" => nil,
                 "type" => "host"
               },
               %{
                 "foundation" => "tcpcandidate",
                 "ip" => "9.9.9.1",
                 "protocol" => "tcp",
                 "tcpType" => "passive",
                 "type" => "host"
               },
               %{
                 "foundation" => "udpcandidate",
                 "ip" => "9.9.9.2",
                 "protocol" => "udp",
                 "tcpType" => nil,
                 "type" => "host"
               },
               %{
                 "foundation" => "tcpcandidate",
                 "ip" => "9.9.9.2",
                 "protocol" => "tcp",
                 "tcpType" => "passive",
                 "type" => "host"
               },
               %{
                 "foundation" => "udpcandidate",
                 "ip" => "127.0.0.1",
                 "protocol" => "udp",
                 "tcpType" => nil,
                 "type" => "host"
               },
               %{
                 "foundation" => "tcpcandidate",
                 "ip" => "127.0.0.1",
                 "protocol" => "tcp",
                 "tcpType" => "passive",
                 "type" => "host"
               }
             ],
             ice_candidates
           )

    assert "new" == Mediasoup.WebRtcTransport.ice_state(transport)
    assert nil == Mediasoup.WebRtcTransport.ice_selected_tuple(transport)
    assert match?(%{"role" => "auto"}, Mediasoup.WebRtcTransport.dtls_parameters(transport))
    assert "new" == Mediasoup.WebRtcTransport.dtls_state(transport)
    assert "new" == Mediasoup.WebRtcTransport.sctp_state(transport)

    Mediasoup.WebRtcTransport.close(transport)
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end
end

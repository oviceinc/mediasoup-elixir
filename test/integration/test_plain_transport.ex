defmodule IntegrateTest.PlainTransportTest do
  @moduledoc """
  test for PlainTransport with dialyzer check
  """

  import ExUnit.Assertions
  alias Mediasoup.{PlainTransport, Router}

  defp init(worker) do
    alias Mediasoup.{Worker, Router}

    Worker.event(worker, self())

    {:ok, router} =
      Worker.create_router(worker, %{
        mediaCodecs: media_codecs()
      })

    {worker, router}
  end

  def webrtc_init(worker) do
    alias Mediasoup.{Worker, Router}
    Worker.event(worker, self())

    {:ok, router} =
      Worker.create_router(worker, %{
        mediaCodecs: media_codecs()
      })

    {:ok, transport_1} =
      Router.create_webrtc_transport(router, %{
        listenIps: {
          %{
            ip: "127.0.0.1"
          }
        }
      })

    {worker, router, transport_1}
  end

  defp media_codecs() do
    {
      %{
        kind: "audio",
        mimeType: "audio/opus",
        clockRate: 48_000,
        channels: 2,
        parameters: %{"foo" => "bar"},
        rtcpFeedback: []
      },
      %{
        kind: "video",
        mimeType: "video/VP8",
        clockRate: 90000,
        parameters: %{},
        rtcpFeedback: []
      },
      %{
        kind: "video",
        mimeType: "video/H264",
        clockRate: 90_000,
        parameters: %{
          "level-asymmetry-allowed" => 1,
          "packetization-mode" => 1,
          "profile-level-id" => "4d0032",
          "foo" => "bar"
        },
        rtcpFeedback: []
      }
    }
  end

  def consumer_device_capabilities() do
    %{
      codecs:
        {%{
           kind: "audio",
           mimeType: "audio/opus",
           preferredPayloadType: 100,
           clockRate: 48000,
           channels: 2,
           parameters: %{},
           rtcpFeedback: []
         },
         %{
           kind: "video",
           mimeType: "video/VP8",
           preferredPayloadType: 101,
           clockRate: 90000,
           parameters: %{},
           rtcpFeedback: [
             %{type: "nack"},
             %{type: "ccm", parameter: "fir"},
             %{type: "transport-cc"}
           ]
         },
         %{
           kind: "video",
           mimeType: "video/rtx",
           payloadType: 102,
           clockRate: 90000,
           parameters: %{
             "apt" => 101
           },
           rtcpFeedback: []
         }},
      headerExtensions: {
        %{
          kind: "video",
          uri: "http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time",
          preferredId: 4,
          preferredEncrypt: false,
          direction: "sendrecv"
        },
        %{
          kind: "video",
          uri: "http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01",
          preferredId: 5,
          preferredEncrypt: false,
          direction: "sendrecv"
        },
        %{
          kind: "audio",
          uri: "urn:ietf:params:rtp-hdrext:ssrc-audio-level",
          preferredId: 10,
          preferredEncrypt: false,
          direction: "sendrecv"
        }
      },
      fecMechanisms: {}
    }
  end

  def video_producer_options() do
    %{
      kind: "video",
      rtpParameters: %{
        mid: "VIDEO",
        codecs:
          {%{
             mimeType: "video/VP8",
             payloadType: 112,
             clockRate: 90000,
             parameters: %{
               "packetization-mode" => 1,
               "profile-level-id" => "4d0032"
             },
             rtcpFeedback: [
               %{type: "nack"},
               %{type: "nack", parameter: "pli"},
               %{type: "goog-remb"}
             ]
           },
           %{
             mimeType: "video/rtx",
             payloadType: 113,
             clockRate: 90000,
             parameters: %{
               "apt" => 112
             },
             rtcpFeedback: []
           }},
        headerExtensions: [
          %{
            uri: "urn:ietf:params:rtp-hdrext:sdes:mid",
            id: 10,
            encrypt: false
          },
          %{
            uri: "urn:ietf:params:rtp-hdrext:sdes:mid",
            id: 10,
            encrypt: false
          },
          %{
            uri: "urn:3gpp:video-orientation",
            id: 13,
            encrypt: false
          }
        ],
        encodings: [
          %{
            ssrc: 22_222_222,
            rtx: %{ssrc: 22_222_223}
          },
          %{
            ssrc: 22_222_224,
            rtx: %{ssrc: 22_222_225}
          },
          %{
            ssrc: 22_222_226,
            rtx: %{ssrc: 22_222_227}
          },
          %{
            ssrc: 22_222_228,
            rtx: %{ssrc: 22_222_229}
          }
        ],
        rtcp: %{
          cname: "FOOBAR",
          reducedSize: true
        }
      }
    }
  end

  def create_succeeds(worker) do
    test_create_succeeds_with_ip_only(worker)
    test_create_succeeds_with_sctp_enabled(worker)
    test_create_succeeds_with_srtp_enabled(worker)
  end

  defp test_create_succeeds_with_ip_only(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_plain_transport(router, %{listenIp: %{ip: "127.0.0.1"}, comedia: false})

    assert transport.id == PlainTransport.id(transport)

    assert match?(
             %{"localIp" => "127.0.0.1", "localPort" => _, "protocol" => "udp"},
             PlainTransport.tuple(transport)
           )
  end

  defp test_create_succeeds_with_sctp_enabled(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_plain_transport(router, %{listenIp: %{ip: "127.0.0.1"}, enableSctp: true})

    assert transport.id == PlainTransport.id(transport)

    assert match?(
             %{"localIp" => "127.0.0.1", "localPort" => _, "protocol" => "udp"},
             PlainTransport.tuple(transport)
           )

    assert %{"MIS" => 1024, "OS" => 1024, "maxMessageSize" => 262_144, "port" => 5000} ==
             PlainTransport.sctp_parameters(transport)

    assert PlainTransport.sctp_state(transport) == "new"
  end

  defp test_create_succeeds_with_srtp_enabled(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_plain_transport(router, %{listenIp: %{ip: "127.0.0.1"}, enableSrtp: true})

    assert transport.id == PlainTransport.id(transport)

    assert match?(
             %{"localIp" => "127.0.0.1", "localPort" => _, "protocol" => "udp"},
             PlainTransport.tuple(transport)
           )

    assert match?(
             %{
               "cryptoSuite" => "AES_CM_128_HMAC_SHA1_80",
               "keyBase64" => _
             },
             PlainTransport.srtp_parameters(transport)
           )
  end

  def close(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_plain_transport(router, %{
        listenIp: %{
          ip: "127.0.0.1"
        }
      })

    assert PlainTransport.id(transport) == transport.id
    PlainTransport.close(transport)
    assert PlainTransport.closed?(transport)
  end

  def create_non_bindable_ip(worker) do
    {_worker, router} = init(worker)

    Mediasoup.Worker.update_settings(worker, %Mediasoup.Worker.UpdateableSettings{
      log_level: :none,
      log_tags: []
    })

    {:error, _message} =
      Router.create_plain_transport(router, %{
        listenIp: %{
          ip: "8.8.8.8"
        }
      })
  end

  def get_stats_succeeds(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_plain_transport(router, %{
        listenIp: %{
          ip: "127.0.0.1"
        }
      })

    stats = PlainTransport.get_stats(transport)

    transport_id = transport.id

    assert match?(
             [
               %{
                 "bytesReceived" => 0,
                 "bytesSent" => 0,
                 "comedia" => false,
                 "probationBytesSent" => 0,
                 "probationSendBitrate" => 0,
                 "recvBitrate" => 0,
                 "rtcpMux" => true,
                 "rtcpTuple" => nil,
                 "rtpBytesReceived" => 0,
                 "rtpBytesSent" => 0,
                 "rtpRecvBitrate" => 0,
                 "rtpSendBitrate" => 0,
                 "rtxBytesReceived" => 0,
                 "rtxBytesSent" => 0,
                 "rtxRecvBitrate" => 0,
                 "rtxSendBitrate" => 0,
                 "sctpState" => nil,
                 "sendBitrate" => 0,
                 "timestamp" => _,
                 "transportId" => ^transport_id,
                 "tuple" => %{
                   "localIp" => "127.0.0.1",
                   "localPort" => _,
                   "protocol" => "udp"
                 }
               }
             ],
             stats
           )
  end

  def connect_succeeds(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_plain_transport(router, %{
        listenIp: %{
          ip: "127.0.0.1"
        }
      })

    assert {:ok} == PlainTransport.connect(transport, %{ip: "127.0.0.1", port: 4000})
  end

  def close_event(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_plain_transport(router, %{
        listenIp: %{
          ip: "127.0.0.1"
        }
      })

    PlainTransport.event(transport, self())
    PlainTransport.close(transport)

    assert_receive {:on_close}
  end

  def close_router_event(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_plain_transport(router, %{
        listenIp: %{
          ip: "127.0.0.1"
        }
      })

    PlainTransport.event(transport, self())
    Mediasoup.Router.close(router)
    assert PlainTransport.closed?(transport)
    assert_receive {:on_close}
  end

  def create_many_plain_transport() do
    {:ok, worker} =
      Mediasoup.Worker.start_link(
        settings: %{
          rtcMinPort: 30000,
          rtcMaxPort: 30005,
          logLevel: :none
        }
      )

    {_worker, router} = init(worker)

    transports =
      1..6
      |> Enum.map(fn _ ->
        {:ok, transport} =
          Router.create_plain_transport(router, %{
            listenIp: %{
              ip: "127.0.0.1"
            }
          })

        transport
      end)

    # no more available ports
    {:error, _} =
      Router.create_plain_transport(router, %{
        listenIp: %{
          ip: "127.0.0.1"
        }
      })

    transports
    |> Enum.map(fn transport ->
      PlainTransport.close(transport)
    end)
  end

  def produce_success(worker) do
    {_worker, router} = init(worker)

    {:ok, plain_transport} =
      Router.create_plain_transport(router, %{
        listenIp: %{
          ip: "127.0.0.1"
        }
      })

    assert {:ok} == PlainTransport.connect(plain_transport, %{ip: "127.0.0.1", port: 4000})

    assert match?(
             {:ok, _},
             PlainTransport.produce(plain_transport, video_producer_options())
           )
  end

  def consume_success(worker) do
    {_worker, router, webrtc_transport} = webrtc_init(worker)

    {:ok, plain_transport} =
      Router.create_plain_transport(router, %{
        listenIp: %{
          ip: "127.0.0.1"
        }
      })

    assert {:ok} == PlainTransport.connect(plain_transport, %{ip: "127.0.0.1", port: 4000})

    {:ok, video_producer} =
      Mediasoup.WebRtcTransport.produce(webrtc_transport, video_producer_options())

    assert match?(
             {:ok, _},
             PlainTransport.consume(plain_transport, %{
               producerId: video_producer.id,
               rtpCapabilities: consumer_device_capabilities()
             })
           )
  end
end

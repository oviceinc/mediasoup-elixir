defmodule IntegrateTest.WebRtcTransportTest do
  @moduledoc """
  test for WebRtcTransport with dializer check
  """
  import ExUnit.Assertions
  alias Mediasoup.{WebRtcTransport, Router, WebRtcServer, Worker}

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

  defp init(worker) do
    alias Mediasoup.{Worker, Router}

    Worker.event(worker, self())

    {:ok, router} =
      Worker.create_router(worker, %{
        mediaCodecs: media_codecs()
      })

    {worker, router}
  end

  def create_succeeds(worker) do
    {_worker, router} = init(worker)

    {:ok, _transport} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1"
          }
        ]
      })

    {:ok, transport1} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
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
        ],
        enableTcp: true,
        preferUdp: true,
        enableSctp: true,
        numSctpStreams: %{
          OS: 2048,
          MIS: 2048
        },
        maxSctpMessageSize: 1_000_000
      })

    assert WebRtcTransport.ice_role(transport1) === "controlled"
    assert WebRtcTransport.ice_parameters(transport1)["iceLite"] === true

    assert WebRtcTransport.sctp_parameters(transport1) === %{
             "MIS" => 2048,
             "OS" => 2048,
             "maxMessageSize" => 1_000_000,
             "port" => 5000
           }

    ice_candidates = Mediasoup.WebRtcTransport.ice_candidates(transport1)

    assert match?(
             [
               %{
                 "foundation" => "udpcandidate",
                 "address" => "9.9.9.1",
                 "protocol" => "udp",
                 "type" => "host"
               },
               %{
                 "foundation" => "tcpcandidate",
                 "address" => "9.9.9.1",
                 "protocol" => "tcp",
                 "tcpType" => "passive",
                 "type" => "host"
               },
               %{
                 "foundation" => "udpcandidate",
                 "address" => "9.9.9.2",
                 "protocol" => "udp",
                 "type" => "host"
               },
               %{
                 "foundation" => "tcpcandidate",
                 "address" => "9.9.9.2",
                 "protocol" => "tcp",
                 "tcpType" => "passive",
                 "type" => "host"
               },
               %{
                 "foundation" => "udpcandidate",
                 "address" => "127.0.0.1",
                 "protocol" => "udp",
                 "type" => "host"
               },
               %{
                 "foundation" => "tcpcandidate",
                 "address" => "127.0.0.1",
                 "protocol" => "tcp",
                 "tcpType" => "passive",
                 "type" => "host"
               }
             ],
             ice_candidates
           )

    [
      %{
        "priority" => priority1
      },
      %{
        "priority" => priority2
      },
      %{
        "priority" => priority3
      },
      %{
        "priority" => priority4
      },
      %{
        "priority" => priority5
      },
      %{
        "priority" => priority6
      }
    ] = ice_candidates

    assert priority1 > priority2
    assert priority2 > priority3
    assert priority3 > priority4
    assert priority4 > priority5
    assert priority5 > priority6

    assert "new" == WebRtcTransport.ice_state(transport1)
    assert nil == WebRtcTransport.ice_selected_tuple(transport1)
    assert match?(%{"role" => "auto"}, WebRtcTransport.dtls_parameters(transport1))
    assert "new" == WebRtcTransport.dtls_state(transport1)
    assert "new" == WebRtcTransport.sctp_state(transport1)
  end

  def close(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1"
          }
        ]
      })

    assert is_binary(Mediasoup.Transport.id(transport))
    Mediasoup.Transport.close(transport)
    Mediasoup.Transport.closed?(transport)
  end

  def create_non_bindable_ip(worker) do
    {_worker, router} = init(worker)

    Mediasoup.Worker.update_settings(worker, %Mediasoup.Worker.UpdateableSettings{
      log_level: :none,
      log_tags: []
    })

    {:error, _message} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "8.8.8.8"
          }
        ]
      })
  end

  def get_stats_succeeds(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1"
          }
        ]
      })

    stats = WebRtcTransport.get_stats(transport)

    transport_id = transport.id

    [
      %{
        "bytesReceived" => 0,
        "bytesSent" => 0,
        "dtlsState" => "new",
        "iceRole" => "controlled",
        "iceState" => "new",
        "probationBytesSent" => 0,
        "probationSendBitrate" => 0,
        "recvBitrate" => 0,
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
        "transportId" => ^transport_id
      }
    ] = stats
  end

  def connect_succeeds(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1"
          }
        ]
      })

    #  dtlsParameters format example
    #  %{
    #    "role" => "auto",
    #    "fingerprints" => [%{"algorithm" => "sha-1", "value" => "69:3A:AF:5D:46:EB:22:84:68:B3:3D:67:81:19:A0:41:79:AD:B0:EF"},
    #     %{"algorithm" => "sha-224", "value" => "78:12:E4:E6:D3:B3:55:C0:2C:D9:E2:09:54:35:34:03:D9:2F:EF:F0:FC:F7:E8:8C:BE:F0:0A:A3"},
    #     %{"algorithm" => "sha-256", "value" => "E6:8A:43:7D:C7:B8:2B:EB:5B:0E:0C:F0:0C:8C:6F:F8:9A:0E:1A:46:8B:0D:98:90:D1:82:26:C4:46:25:61:3C"},
    #     %{"algorithm" => "sha-384", "value" => "21:82:EB:3B:50:1D:8F:7C:19:B8:8B:D5:62:7F:3B:87:80:53:36:1E:10:E3:7C:B8:B2:E2:C9:D8:8F:DD:6B:85:7D:1D:5F:3A:DA:A5:1C:11:7E:40:A1:94:97:A6:14:7F"},
    #     %{"algorithm" => "sha-512", "value" => "D1:4B:44:62:76:2B:A8:ED:B8:C9:E6:A3:B0:E8:2A:7F:81:7E:F9:29:11:92:D5:86:72:82:40:35:66:C8:84:ED:AD:3B:08:59:ED:7D:65:C2:77:C4:D7:6F:AE:77:42:A5:73:E2:FB:D0:72:99:71:B6:71:F1:06:8A:13:B7:91:87"}]
    #  }

    dtls_parameters = %{
      "role" => "client",
      "fingerprints" => [
        %{
          "algorithm" => "sha-256",
          "value" =>
            "82:5A:68:3D:36:C3:0A:DE:AF:E7:32:43:D2:88:83:57:AC:2D:65:E5:80:C4:B6:FB:AF:1A:A0:21:9F:6D:0C:AD"
        }
      ]
    }

    {:ok} =
      WebRtcTransport.connect(transport, %{
        dtlsParameters: dtls_parameters
      })

    Mediasoup.Worker.update_settings(worker, %Mediasoup.Worker.UpdateableSettings{
      log_level: :none,
      log_tags: []
    })

    # Must fail if connected.
    {:error, _error} =
      WebRtcTransport.connect(transport, %{
        dtlsParameters: dtls_parameters
      })

    assert match?(%{"role" => "server"}, WebRtcTransport.dtls_parameters(transport))
  end

  def set_max_incoming_bitrate_succeeds(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1"
          }
        ]
      })

    {:ok} = Mediasoup.WebRtcTransport.set_max_incoming_bitrate(transport, 100_000)
  end

  def set_max_outgoing_bitrate_succeeds(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1"
          }
        ]
      })

    {:ok} = Mediasoup.WebRtcTransport.set_max_outgoing_bitrate(transport, 100_000)
  end

  def restart_ice_succeeds(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1"
          }
        ]
      })

    previouse_ice_parameters = WebRtcTransport.ice_parameters(transport)

    {:ok, ice_parameters} = WebRtcTransport.restart_ice(transport)

    assert ice_parameters["usernameFragment"] !== previouse_ice_parameters["usernameFragment"]
    assert ice_parameters["password"] !== previouse_ice_parameters["password"]
  end

  def close_event(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1"
          }
        ]
      })

    Mediasoup.Transport.event(transport, self())
    Mediasoup.Transport.close(transport)

    assert_receive {:on_close}
  end

  def close_router_event(worker) do
    {_worker, router} = init(worker)

    {:ok, transport} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1"
          }
        ]
      })

    Mediasoup.Transport.event(transport, self())
    assert false == Mediasoup.Transport.closed?(transport)
    Mediasoup.Router.close(router)
    assert Mediasoup.Transport.closed?(transport)
    assert_receive {:on_close}
  end

  def create_many_webrtc_transport() do
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
          Router.create_webrtc_transport(router, %{
            listenIps: [
              %{
                ip: "127.0.0.1",
                announcedIp: "9.9.9.1"
              }
            ]
          })

        transport
      end)

    # no more available ports
    {:error, _} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1"
          }
        ]
      })

    transports
    |> Enum.map(fn transport ->
      WebRtcTransport.close(transport)
    end)
  end

  def create_with_webrtc_server_succeeds(worker) do
    {_worker, router} = init(worker)

    {:ok, webrtc_server} =
      Worker.create_webrtc_server(worker, %WebRtcServer.Options{
        listen_infos: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1",
            port: 10111,
            protocol: :tcp
          },
          %{
            ip: "0.0.0.0",
            announcedIp: "9.9.9.2",
            port: 10112,
            protocol: :tcp
          },
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1",
            port: 10111,
            protocol: :udp
          },
          %{
            ip: "0.0.0.0",
            announcedIp: "9.9.9.2",
            port: 10112,
            protocol: :udp
          }
        ]
      })

    {:ok, _transport} =
      Router.create_webrtc_transport(router, %WebRtcTransport.Options{
        webrtc_server: webrtc_server
      })

    {:ok, transport1} =
      Router.create_webrtc_transport(router, %WebRtcTransport.Options{
        webrtc_server: webrtc_server,
        enable_sctp: true,
        enable_tcp: true,
        enable_udp: true,
        num_sctp_streams: %{
          OS: 2048,
          MIS: 2048
        },
        max_sctp_message_size: 1_000_000
      })

    assert WebRtcTransport.ice_role(transport1) === "controlled"
    assert WebRtcTransport.ice_parameters(transport1)["iceLite"] === true

    ice_candidates = Mediasoup.WebRtcTransport.ice_candidates(transport1)

    assert match?(
             [
               %{
                 "foundation" => "tcpcandidate",
                 "address" => "9.9.9.1",
                 "protocol" => "tcp",
                 "tcpType" => "passive",
                 "type" => "host"
               },
               %{
                 "foundation" => "tcpcandidate",
                 "address" => "9.9.9.2",
                 "protocol" => "tcp",
                 "tcpType" => "passive",
                 "type" => "host"
               },
               %{
                 "foundation" => "udpcandidate",
                 "address" => "9.9.9.1",
                 "protocol" => "udp",
                 "type" => "host"
               },
               %{
                 "foundation" => "udpcandidate",
                 "address" => "9.9.9.2",
                 "protocol" => "udp",
                 "type" => "host"
               }
             ],
             ice_candidates
           )
  end
end

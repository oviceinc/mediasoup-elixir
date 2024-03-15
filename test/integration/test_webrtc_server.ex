defmodule IntegrateTest.WebRtcServerTest do
  @moduledoc """
  test for WebRtcServer with dializer check
  """
  import ExUnit.Assertions
  alias Mediasoup.{Worker, WebRtcTransport, Router, WebRtcServer}

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

  def create_webrtc_server_succeeds(worker) do
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

  def create_webrtc_server_without_specifying_port_succeeds(worker) do
    {_worker, router} = init(worker)

    {:ok, webrtc_server} =
      Worker.create_webrtc_server(worker, %WebRtcServer.Options{
        listen_infos: [
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.1",
            protocol: :udp
          },
          %{
            ip: "127.0.0.1",
            announcedIp: "9.9.9.2",
            protocol: :tcp
          }
        ]
      })

    {:ok, _transport} =
      Router.create_webrtc_transport(router, %WebRtcTransport.Options{
        webrtc_server: webrtc_server
      })

    dump = WebRtcServer.dump(webrtc_server)
    assert dump["id"] == WebRtcServer.id(webrtc_server)
    assert List.first(dump["udpSockets"])["ip"] == "127.0.0.1"
    assert List.first(dump["tcpServers"])["ip"] == "127.0.0.1"
    assert List.first(dump["tcpServers"])["ip"] == "127.0.0.1"

    #  assert_eq!(dump.webrtc_transport_ids, HashedSet::default());
    #  assert_eq!(dump.local_ice_username_fragments, vec![]);
    #  assert_eq!(dump.tuple_hashes, vec![]);
  end

  def unavailable_infos_fails(worker) do
    # Using an unavailable listen IP.
    {:error, _error} =
      Worker.create_webrtc_server(worker, %WebRtcServer.Options{
        listen_infos: [
          %{
            ip: "1.2.3.4",
            protocol: :udp
          }
        ]
      })

    # Using the same UDP port twice.
    {:error, _error} =
      Worker.create_webrtc_server(worker, %WebRtcServer.Options{
        listen_infos: [
          %{
            ip: "127.0.0.1",
            protocol: :udp,
            port: 10111
          },
          %{
            ip: "127.0.0.1",
            protocol: :udp,
            port: 10111
          }
        ]
      })

    # Using the same UDP port in a second server.
    {:ok, _server} =
      Worker.create_webrtc_server(worker, %WebRtcServer.Options{
        listen_infos: [
          %{
            ip: "127.0.0.1",
            protocol: :udp,
            port: 12348
          }
        ]
      })

    {:error, _error} =
      Worker.create_webrtc_server(worker, %WebRtcServer.Options{
        listen_infos: [
          %{
            ip: "127.0.0.1",
            protocol: :udp,
            port: 12348
          }
        ]
      })
  end
end

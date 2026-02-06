defmodule WebRtcTransportTest do
  use ExUnit.Case

  setup do
    Mediasoup.LoggerProxy.start_link(max_level: :info)
    {:ok, worker} = Mediasoup.Worker.start_link()

    %{worker: worker}
  end

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  test "normalize option" do
    alias Mediasoup.WebRtcTransport.Options

    assert %Options{
             listen_infos: [%{ip: "127.0.0.1", announcedAddress: nil, port: nil, protocol: :udp}]
           } =
             Options.normalize(
               Options.from_map(%{
                 listenIps: [
                   %{
                     ip: "127.0.0.1"
                   }
                 ]
               })
             )

    assert %Options{
             listen_infos: [
               %{ip: "127.0.0.1", announcedAddress: nil, port: nil, protocol: :udp},
               %{ip: "127.0.0.1", announcedAddress: nil, port: nil, protocol: :tcp}
             ]
           } =
             Options.normalize(%Options{
               listen_ips: [
                 %{
                   ip: "127.0.0.1"
                 }
               ],
               prefer_udp: true,
               prefer_tcp: false,
               enable_tcp: true
             })

    assert %Options{
             listen_infos: [
               %{ip: "127.0.0.1", announcedAddress: nil, port: nil, protocol: :udp},
               %{ip: "127.0.0.1", announcedAddress: nil, port: nil, protocol: :tcp}
             ]
           } =
             Options.normalize(%Options{
               listen: [
                 %{ip: "127.0.0.1", announcedIp: nil, port: nil, protocol: :udp},
                 %{ip: "127.0.0.1", announcedIp: nil, port: nil, protocol: :tcp}
               ]
             })

    assert %Options{
             listen_infos: [
               %{ip: "127.0.0.1", announcedAddress: nil, port: nil, protocol: :tcp},
               %{ip: "127.0.0.1", announcedAddress: nil, port: nil, protocol: :udp}
             ]
           } =
             Options.normalize(%Options{
               listen_ips: [
                 %{
                   ip: "127.0.0.1"
                 }
               ],
               prefer_udp: false,
               prefer_tcp: true,
               enable_udp: true,
               enable_tcp: true
             })

    assert %Options{
             webrtc_server: %Mediasoup.WebRtcServer{id: "test"}
           } =
             Options.normalize(%Options{
               listen: %Mediasoup.WebRtcServer{id: "test"}
             })

    assert %Options{
             listen_infos: []
           } =
             Options.normalize(%Options{
               listen_ips: [
                 %{
                   ip: "127.0.0.1"
                 }
               ],
               prefer_udp: true,
               prefer_tcp: false,
               enable_tcp: false,
               enable_udp: false
             })

    assert %Options{
             listen_infos: [
               %{announcedAddress: nil, ip: "127.0.0.1", port: nil, protocol: :tcp}
             ]
           } =
             Options.normalize(%Options{
               listen_ips: [
                 %{
                   ip: "127.0.0.1"
                 }
               ],
               enable_tcp: true,
               enable_udp: false
             })

    assert %Options{
             listen_infos: [
               %{announcedAddress: nil, ip: "127.0.0.1", port: nil, protocol: :tcp}
             ]
           } =
             Options.normalize(%Options{
               listen_ips: ["127.0.0.1"],
               enable_tcp: true,
               enable_udp: false
             })
  end

  test "create_succeeds", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.create_succeeds(worker)
  end

  test "close", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.close(worker)
  end

  test "create_non_bindable_ip", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.create_non_bindable_ip(worker)
  end

  test "get_stats_succeeds", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.get_stats_succeeds(worker)
  end

  test "connect_succeeds", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.connect_succeeds(worker)
  end

  test "set_max_incoming_bitrate_succeeds", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.set_max_incoming_bitrate_succeeds(worker)
  end

  test "set_max_outgoing_bitrate_succeeds", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.set_max_outgoing_bitrate_succeeds(worker)
  end

  test "restart_ice_succeeds", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.restart_ice_succeeds(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.close_event(worker)
  end

  test "close_router_event", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.close_router_event(worker)
  end

  test "create_many_webrtc_transport" do
    IntegrateTest.WebRtcTransportTest.create_many_webrtc_transport()
  end

  test "create_with_webrtc_server_succeeds", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.create_with_webrtc_server_succeeds(worker)
  end

  test "event_notifications", %{worker: worker} do
    IntegrateTest.WebRtcTransportTest.event_notifications(worker)
  end

  test "struct_from_pid/1 returns the correct struct", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %Mediasoup.WebRtcTransport.Options{
        listen_ips: [%{ip: "127.0.0.1"}]
      })

    struct = Mediasoup.WebRtcTransport.struct_from_pid(transport.pid)
    assert struct.id == transport.id
    Mediasoup.WebRtcTransport.close(transport)
  end

  test "id/1 returns the correct id", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %Mediasoup.WebRtcTransport.Options{
        listen_ips: [%{ip: "127.0.0.1"}]
      })

    assert Mediasoup.WebRtcTransport.id(transport) == transport.id
    Mediasoup.WebRtcTransport.close(transport)
  end

  test "ice_state/1 returns the current ICE state", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %Mediasoup.WebRtcTransport.Options{
        listen_ips: [%{ip: "127.0.0.1"}]
      })

    assert Mediasoup.WebRtcTransport.ice_state(transport) == "new"
    Mediasoup.WebRtcTransport.close(transport)
  end

  test "ice_selected_tuple/1 returns the selected tuple", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %Mediasoup.WebRtcTransport.Options{
        listen_ips: [%{ip: "127.0.0.1"}]
      })

    assert Mediasoup.WebRtcTransport.ice_selected_tuple(transport) == nil
    Mediasoup.WebRtcTransport.close(transport)
  end

  test "dtls_parameters/1 returns the DTLS parameters", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %Mediasoup.WebRtcTransport.Options{
        listen_ips: [%{ip: "127.0.0.1"}]
      })

    params = Mediasoup.WebRtcTransport.dtls_parameters(transport)
    assert is_map(params)
    assert Map.has_key?(params, "fingerprints")
    Mediasoup.WebRtcTransport.close(transport)
  end

  test "dtls_state/1 returns the current DTLS state", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %Mediasoup.WebRtcTransport.Options{
        listen_ips: [%{ip: "127.0.0.1"}]
      })

    assert Mediasoup.WebRtcTransport.dtls_state(transport) == "new"
    Mediasoup.WebRtcTransport.close(transport)
  end

  test "sctp_state/1 returns the current SCTP state", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %Mediasoup.WebRtcTransport.Options{
        listen_ips: [%{ip: "127.0.0.1"}],
        enable_sctp: true
      })

    assert Mediasoup.WebRtcTransport.sctp_state(transport) == "new"
    Mediasoup.WebRtcTransport.close(transport)
  end

  test "sctp_parameters/1 returns the SCTP parameters", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %Mediasoup.WebRtcTransport.Options{
        listen_ips: [%{ip: "127.0.0.1"}],
        enable_sctp: true
      })

    params = Mediasoup.WebRtcTransport.sctp_parameters(transport)
    assert is_map(params)
    assert Map.has_key?(params, "port")
    Mediasoup.WebRtcTransport.close(transport)
  end

  test "ice_parameters/1 returns the ICE parameters", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %Mediasoup.WebRtcTransport.Options{
        listen_ips: [%{ip: "127.0.0.1"}]
      })

    params = Mediasoup.WebRtcTransport.ice_parameters(transport)
    assert is_map(params)
    assert Map.has_key?(params, "usernameFragment")
    assert Map.has_key?(params, "password")
    Mediasoup.WebRtcTransport.close(transport)
  end

  test "ice_candidates/1 returns the ICE candidates", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %Mediasoup.WebRtcTransport.Options{
        listen_ips: [%{ip: "127.0.0.1"}]
      })

    candidates = Mediasoup.WebRtcTransport.ice_candidates(transport)
    assert is_list(candidates)
    assert candidates != []
    Mediasoup.WebRtcTransport.close(transport)
  end

  test "ice_role/1 returns the ICE role", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_webrtc_transport(router, %Mediasoup.WebRtcTransport.Options{
        listen_ips: [%{ip: "127.0.0.1"}]
      })

    assert Mediasoup.WebRtcTransport.ice_role(transport) == "controlled"
    Mediasoup.WebRtcTransport.close(transport)
  end
end

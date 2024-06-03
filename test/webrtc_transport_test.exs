defmodule MediasoupElixirWebRtcTransportTest do
  use ExUnit.Case

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  setup do
    Mediasoup.LoggerProxy.start_link(max_level: :info)
    {:ok, worker} = Mediasoup.Worker.start_link()
    %{worker: worker}
  end

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

  test "set_max_incoming_bitrate_succeeds", %{
    worker: worker
  } do
    IntegrateTest.WebRtcTransportTest.set_max_incoming_bitrate_succeeds(worker)
  end

  test "set_max_outgoing_bitrate_succeeds", %{
    worker: worker
  } do
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
end

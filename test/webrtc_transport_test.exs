defmodule MediasoupElixirWebRtcTransportTest do
  use ExUnit.Case

  test "create_succeeds" do
    IntegrateTest.WebRtcTransportTest.create_succeeds()
  end

  test "close" do
    IntegrateTest.WebRtcTransportTest.close()
  end

  test "create_non_bindable_ip" do
    IntegrateTest.WebRtcTransportTest.create_non_bindable_ip()
  end

  test "get_stats_succeeds" do
    IntegrateTest.WebRtcTransportTest.get_stats_succeeds()
  end

  test "connect_succeeds" do
    IntegrateTest.WebRtcTransportTest.connect_succeeds()
  end

  test "set_max_incoming_bitrate_succeeds" do
    IntegrateTest.WebRtcTransportTest.set_max_incoming_bitrate_succeeds()
  end

  test "set_max_outgoing_bitrate_succeeds" do
    IntegrateTest.WebRtcTransportTest.set_max_outgoing_bitrate_succeeds()
  end

  test "restart_ice_succeeds" do
    IntegrateTest.WebRtcTransportTest.restart_ice_succeeds()
  end

  test "close_event" do
    IntegrateTest.WebRtcTransportTest.close_event()
  end
end

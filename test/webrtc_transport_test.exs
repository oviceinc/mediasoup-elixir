defmodule MediasoupElixirWebRtcTransportTest do
  use ExUnit.Case

  setup do
    {:ok, struct_worker} = Mediasoup.create_worker()

    {:ok, process_worker} = Mediasoup.Worker.start_link()

    %{struct_worker: struct_worker, process_worker: process_worker}
  end

  test "create_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.WebRtcTransportTest.create_succeeds(struct_worker)
    IntegrateTest.WebRtcTransportTest.create_succeeds(process_worker)
  end

  test "close", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.WebRtcTransportTest.close(struct_worker)
    IntegrateTest.WebRtcTransportTest.close(process_worker)
  end

  test "create_non_bindable_ip", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.WebRtcTransportTest.create_non_bindable_ip(struct_worker)
    IntegrateTest.WebRtcTransportTest.create_non_bindable_ip(process_worker)
  end

  test "get_stats_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.WebRtcTransportTest.get_stats_succeeds(struct_worker)
    IntegrateTest.WebRtcTransportTest.get_stats_succeeds(process_worker)
  end

  test "connect_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.WebRtcTransportTest.connect_succeeds(struct_worker)
    IntegrateTest.WebRtcTransportTest.connect_succeeds(process_worker)
  end

  test "set_max_incoming_bitrate_succeeds", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.WebRtcTransportTest.set_max_incoming_bitrate_succeeds(struct_worker)
    IntegrateTest.WebRtcTransportTest.set_max_incoming_bitrate_succeeds(process_worker)
  end

  test "set_max_outgoing_bitrate_succeeds", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.WebRtcTransportTest.set_max_outgoing_bitrate_succeeds(struct_worker)
    IntegrateTest.WebRtcTransportTest.set_max_outgoing_bitrate_succeeds(process_worker)
  end

  test "restart_ice_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.WebRtcTransportTest.restart_ice_succeeds(struct_worker)
    IntegrateTest.WebRtcTransportTest.restart_ice_succeeds(process_worker)
  end

  test "close_event", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.WebRtcTransportTest.close_event(struct_worker)
    IntegrateTest.WebRtcTransportTest.close_event(process_worker)
  end

  test "close_router_event", %{struct_worker: _struct_worker, process_worker: process_worker} do
    IntegrateTest.PipeTransportTest.close_router_event(process_worker)
  end
end

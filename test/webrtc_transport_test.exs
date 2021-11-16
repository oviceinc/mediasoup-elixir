defmodule MediasoupElixirWebRtcTransportTest do
  use ExUnit.Case

  setup do
    {:ok, worker} = Mediasoup.Worker.start_link()
    %{worker: worker}
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
    IntegrateTest.PipeTransportTest.close_router_event(worker)
  end
end

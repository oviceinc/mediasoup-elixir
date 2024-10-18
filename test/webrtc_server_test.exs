defmodule MediasoupElixirWebRtcServerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  setup do
    Mediasoup.LoggerProxy.start_link(max_level: :info)
    {:ok, worker} = Mediasoup.Worker.start_link()
    %{worker: worker}
  end

  test "create_webrtc_server_succeeds", %{worker: worker} do
    IntegrateTest.WebRtcServerTest.create_webrtc_server_succeeds(worker)
  end

  test "create_webrtc_server_close", %{worker: worker} do
    IntegrateTest.WebRtcServerTest.create_webrtc_server_close(worker)
  end

  test "create_webrtc_server_without_specifying_port_succeeds", %{worker: worker} do
    IntegrateTest.WebRtcServerTest.create_webrtc_server_without_specifying_port_succeeds(worker)
  end

  test "unavailable_infos_fails", %{worker: worker} do
    assert capture_log(fn ->
             IntegrateTest.WebRtcServerTest.unavailable_infos_fails(worker)
             Process.sleep(10)
           end) =~ "address already in use"
  end
end

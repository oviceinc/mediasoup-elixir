defmodule MediasoupElixirPlainTransportTest do
  use ExUnit.Case

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  setup do
    {:ok, worker} = Mediasoup.Worker.start_link()
    %{worker: worker}
  end

  test "create_succeeds", %{worker: worker} do
    IntegrateTest.PlainTransportTest.create_succeeds(worker)
  end

  test "close", %{worker: worker} do
    IntegrateTest.PlainTransportTest.close(worker)
  end

  test "create_non_bindable_ip", %{worker: worker} do
    IntegrateTest.PlainTransportTest.create_non_bindable_ip(worker)
  end

  test "get_stats_succeeds", %{worker: worker} do
    IntegrateTest.PlainTransportTest.get_stats_succeeds(worker)
  end

  test "connect_succeeds", %{worker: worker} do
    IntegrateTest.PlainTransportTest.connect_succeeds(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.PlainTransportTest.close_event(worker)
  end

  test "close_router_event", %{worker: worker} do
    IntegrateTest.PlainTransportTest.close_router_event(worker)
  end

  test "create_many_plain_transport" do
    IntegrateTest.PlainTransportTest.create_many_plain_transport()
  end

  test "consume_success", %{worker: worker} do
    IntegrateTest.PlainTransportTest.consume_success(worker)
  end
end

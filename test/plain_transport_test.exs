defmodule MediasoupElixirPlainTransportTest do
  use ExUnit.Case

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  setup do
    Mediasoup.LoggerProxy.start_link(max_level: :info)
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

  test "create_with_port", %{worker: worker} do
    IntegrateTest.PlainTransportTest.create_with_port(worker)
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

  test "produce_success", %{worker: worker} do
    IntegrateTest.PlainTransportTest.produce_success(worker)
  end

  test "consume_success", %{worker: worker} do
    IntegrateTest.PlainTransportTest.consume_success(worker)
  end

  test "plain transport event", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport_1} =
      Mediasoup.Router.create_plain_transport(router, %{listenIp: %{ip: "127.0.0.1"}})

    # Register event handler
    assert {:ok} = Mediasoup.PlainTransport.event(transport_1, self(), [:on_tuple])

    # Send internal event directly to test the handler
    send(transport_1.pid, {:nif_internal_event, :on_tuple, %{"localPort" => 1234}})

    # Verify event received
    assert_receive {:on_tuple, %{"localPort" => 1234}}, 5000

    # Cleanup
    Mediasoup.PlainTransport.close(transport_1)
    Mediasoup.Router.close(router)
    Mediasoup.Worker.close(worker)
  end

  test "id/1 returns the correct id", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_plain_transport(router, %{listenIp: %{ip: "127.0.0.1"}})

    assert Mediasoup.PlainTransport.id(transport) == transport.id
    Mediasoup.PlainTransport.close(transport)
  end

  test "tuple/1 returns the correct tuple", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_plain_transport(router, %{listenIp: %{ip: "127.0.0.1"}})

    assert is_struct(Mediasoup.PlainTransport.tuple(transport), TransportTuple)
    Mediasoup.PlainTransport.close(transport)
  end

  test "struct_from_pid/1 returns the correct struct", %{worker: worker} do
    {:ok, router} = Mediasoup.Worker.create_router(worker, %{})

    {:ok, transport} =
      Mediasoup.Router.create_plain_transport(router, %{listenIp: %{ip: "127.0.0.1"}})

    struct = Mediasoup.PlainTransport.struct_from_pid(transport.pid)
    assert struct.id == transport.id
    Mediasoup.PlainTransport.close(transport)
  end
end

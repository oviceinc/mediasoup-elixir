defmodule DataConsumerTest do
  use ExUnit.Case

  setup do
    Mediasoup.LoggerProxy.start_link(max_level: :info)
    {:ok, worker} = Mediasoup.Worker.start_link()

    %{worker: worker}
  end

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  # Define options for data producer
  defp data_producer_options() do
    %Mediasoup.DataProducer.Options{
      sctp_stream_parameters: %{
        streamId: 0,
        ordered: true
      }
    }
  end

  test "data_consumer_succeeds", %{worker: worker} do
    IntegrateTest.DataConsumerTest.data_consume_succeeds(worker)
  end

  test "close", %{worker: worker} do
    IntegrateTest.DataConsumerTest.close(worker)
  end

  test "sctp_stream_parameters", %{worker: worker} do
    IntegrateTest.DataConsumerTest.sctp_stream_parameters(worker)
  end

  test "label", %{worker: worker} do
    IntegrateTest.DataConsumerTest.label(worker)
  end

  test "protocol", %{worker: worker} do
    IntegrateTest.DataConsumerTest.protocol(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.DataConsumerTest.close_event(worker)
  end

  test "closed?/1 returns correct status", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataConsumerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      Mediasoup.WebRtcTransport.consume_data(transport, %Mediasoup.DataConsumer.Options{
        data_producer_id: data_producer |> Mediasoup.DataProducer.id(),
        ordered: true
      })

    assert Mediasoup.DataConsumer.closed?(data_consumer) == false
    Mediasoup.DataConsumer.close(data_consumer)
    assert Mediasoup.DataConsumer.closed?(data_consumer) == true
  end

  test "id/1 returns the correct id", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataConsumerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      Mediasoup.WebRtcTransport.consume_data(transport, %Mediasoup.DataConsumer.Options{
        data_producer_id: data_producer |> Mediasoup.DataProducer.id(),
        ordered: true
      })

    assert Mediasoup.DataConsumer.id(data_consumer) == data_consumer.id

    Mediasoup.DataConsumer.close(data_consumer)
  end

  test "data_producer_id/1 returns the correct data producer id", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataConsumerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      Mediasoup.WebRtcTransport.consume_data(transport, %Mediasoup.DataConsumer.Options{
        data_producer_id: data_producer |> Mediasoup.DataProducer.id(),
        ordered: true
      })

    assert Mediasoup.DataConsumer.data_producer_id(data_consumer) == data_producer.id

    Mediasoup.DataConsumer.close(data_consumer)
  end

  test "type/1 returns the correct type", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataConsumerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      Mediasoup.WebRtcTransport.consume_data(transport, %Mediasoup.DataConsumer.Options{
        data_producer_id: data_producer |> Mediasoup.DataProducer.id(),
        ordered: true
      })

    assert Mediasoup.DataConsumer.type(data_consumer) == "sctp"

    Mediasoup.DataConsumer.close(data_consumer)
  end

  test "struct_from_pid/1 returns the correct struct", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataConsumerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      Mediasoup.WebRtcTransport.consume_data(transport, %Mediasoup.DataConsumer.Options{
        data_producer_id: data_producer |> Mediasoup.DataProducer.id(),
        ordered: true
      })

    struct = Mediasoup.DataConsumer.struct_from_pid(data_consumer.pid)
    assert struct.id == data_consumer.id

    Mediasoup.DataConsumer.close(data_consumer)
  end

  test "event/3 registers event listener", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataConsumerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      Mediasoup.WebRtcTransport.consume_data(transport, %Mediasoup.DataConsumer.Options{
        data_producer_id: data_producer |> Mediasoup.DataProducer.id(),
        ordered: true
      })

    assert {:ok} = Mediasoup.DataConsumer.event(data_consumer, self(), [:on_close])

    Mediasoup.DataConsumer.close(data_consumer)
    assert_receive {:on_close}
  end

  test "handle_info handles :DOWN message correctly", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataConsumerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      Mediasoup.WebRtcTransport.consume_data(transport, %Mediasoup.DataConsumer.Options{
        data_producer_id: data_producer |> Mediasoup.DataProducer.id(),
        ordered: true
      })

    # Register a listener process
    test_pid =
      spawn(fn ->
        receive do
        end
      end)

    Mediasoup.DataConsumer.event(data_consumer, test_pid)

    # Terminate the listener process
    Process.exit(test_pid, :kill)

    ref = Process.monitor(data_consumer.pid)

    # The data_consumer process should still be alive
    refute_receive {:DOWN, ^ref, :process, _, _reason}
    assert Process.alive?(data_consumer.pid)

    Mediasoup.DataConsumer.close(data_consumer)
  end

  test "handle_info handles :on_close message correctly", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataConsumerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      Mediasoup.WebRtcTransport.consume_data(transport, %Mediasoup.DataConsumer.Options{
        data_producer_id: data_producer |> Mediasoup.DataProducer.id(),
        ordered: true
      })

    # Register self as a listener
    Mediasoup.DataConsumer.event(data_consumer, self())

    # Send :on_close message directly to the process
    send(data_consumer.pid, {:on_close})

    ref = Process.monitor(data_consumer.pid)

    # Process should terminate and we should receive the :on_close message
    assert_receive {:on_close}

    assert_receive {:DOWN, ^ref, :process, _, _reason}
    refute Process.alive?(data_consumer.pid)
  end

  test "handle_info handles :nif_internal_event message correctly", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataConsumerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      Mediasoup.WebRtcTransport.consume_data(transport, %Mediasoup.DataConsumer.Options{
        data_producer_id: data_producer |> Mediasoup.DataProducer.id(),
        ordered: true
      })

    # Register self as a listener
    Mediasoup.DataConsumer.event(data_consumer, self())

    # Send :nif_internal_event message directly to the process
    send(data_consumer.pid, {:nif_internal_event, :on_close})

    # Process should terminate and we should receive the :on_close message
    assert_receive {:on_close}

    ref = Process.monitor(data_consumer.pid)

    # Process should be terminated
    assert_receive {:DOWN, ^ref, :process, _, _reason}
    refute Process.alive?(data_consumer.pid)
  end
end

defmodule DataConsumerOptionsTest do
  use ExUnit.Case

  test "from_map/1 creates options from map" do
    map = %{
      "dataProducerId" => "test-id",
      "ordered" => false,
      "maxPacketLifeTime" => 1000,
      "maxRetransmits" => 3
    }

    options = Mediasoup.DataConsumer.Options.from_map(map)
    assert options.data_producer_id == "test-id"
    assert options.ordered == false
    assert options.max_packet_life_time == 1000
    assert options.max_retransmits == 3
  end

  test "from_map/1 handles atom keys" do
    map = %{
      dataProducerId: "test-id-2",
      ordered: true
    }

    options = Mediasoup.DataConsumer.Options.from_map(map)
    assert options.data_producer_id == "test-id-2"
    assert options.ordered == true
  end
end

defmodule DataProducerTest do
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

  test "data_produce_succeeds", %{worker: worker} do
    IntegrateTest.DataProducerTest.data_produce_succeeds(worker)
  end

  test "close", %{worker: worker} do
    IntegrateTest.DataProducerTest.close(worker)
  end

  test "sctp_stream_parameters", %{worker: worker} do
    IntegrateTest.DataProducerTest.sctp_stream_parameters(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.DataProducerTest.close_event(worker)
  end

  test "closed?/1 returns correct status", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataProducerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    assert Mediasoup.DataProducer.closed?(data_producer) == false
    Mediasoup.DataProducer.close(data_producer)
    assert Mediasoup.DataProducer.closed?(data_producer) == true
  end

  test "id/1 returns the correct id", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataProducerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    assert Mediasoup.DataProducer.id(data_producer) == data_producer.id

    Mediasoup.DataProducer.close(data_producer)
  end

  test "type/1 returns the correct type", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataProducerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    assert Mediasoup.DataProducer.type(data_producer) == "sctp"

    Mediasoup.DataProducer.close(data_producer)
  end

  test "struct_from_pid/1 returns the correct struct", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataProducerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    struct = Mediasoup.DataProducer.struct_from_pid(data_producer.pid)
    assert struct.id == data_producer.id

    Mediasoup.DataProducer.close(data_producer)
  end

  test "event/3 registers event listener", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataProducerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    assert {:ok} = Mediasoup.DataProducer.event(data_producer, self(), [:on_close])

    Mediasoup.DataProducer.close(data_producer)
    assert_receive {:on_close}
  end

  test "handles listener process down", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataProducerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    # Create a temporary process that will be used as a listener
    listener_pid =
      spawn(fn ->
        receive do
        end
      end)

    assert {:ok} = Mediasoup.DataProducer.event(data_producer, listener_pid, [:on_close])

    # Kill the listener process
    Process.exit(listener_pid, :kill)

    data_producer_pid = data_producer.pid

    ref = Process.monitor(data_producer_pid)

    refute_receive {:DOWN, ^ref, :process, ^data_producer_pid, _reason}
    refute Mediasoup.DataProducer.closed?(data_producer)

    Mediasoup.DataProducer.close(data_producer)
  end

  test "handles internal close event (deprecated)", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataProducerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    # Register self as a listener
    assert {:ok} = Mediasoup.DataProducer.event(data_producer, self(), [:on_close])

    # Send internal close event
    send(data_producer.pid, {:nif_internal_event, :on_close})

    # Should receive close event
    assert_receive {:on_close}

    ref = Process.monitor(data_producer.pid)

    # Process should be terminated
    assert_receive {:DOWN, ^ref, :process, _, _reason}
    refute Process.alive?(data_producer.pid)
  end

  test "handles piped close event (deprecated)", %{worker: worker} do
    {_worker, _router, transport} = IntegrateTest.DataProducerTest.init(worker)

    {:ok, data_producer} =
      Mediasoup.WebRtcTransport.produce_data(transport, data_producer_options())

    # Register self as a listener
    assert {:ok} = Mediasoup.DataProducer.event(data_producer, self(), [:on_close])

    # Send piped close event
    send(data_producer.pid, {:on_close})

    # Should receive close event
    assert_receive {:on_close}

    ref = Process.monitor(data_producer.pid)

    # Process should be terminated
    assert_receive {:DOWN, ^ref, :process, _, _reason}
    refute Process.alive?(data_producer.pid)
  end
end

defmodule DataProducerOptionsTest do
  use ExUnit.Case

  test "from_map/1 creates options from map" do
    map = %{
      "sctpStreamParameters" => %{
        "streamId" => 1,
        "ordered" => false
      }
    }

    options = Mediasoup.DataProducer.Options.from_map(map)
    assert options.sctp_stream_parameters == %{"streamId" => 1, "ordered" => false}
  end

  test "from_map/1 handles atom keys" do
    map = %{
      sctpStreamParameters: %{
        streamId: 2,
        ordered: true
      }
    }

    options = Mediasoup.DataProducer.Options.from_map(map)
    assert options.sctp_stream_parameters == %{streamId: 2, ordered: true}
  end

  test "from_map/1 handles label and protocol" do
    map = %{
      "label" => "test-label",
      "protocol" => "test-protocol",
      "sctpStreamParameters" => %{
        "streamId" => 1,
        "ordered" => true
      }
    }

    options = Mediasoup.DataProducer.Options.from_map(map)
    assert options.label == "test-label"
    assert options.protocol == "test-protocol"
    assert options.sctp_stream_parameters == %{"streamId" => 1, "ordered" => true}
  end

  test "from_map/1 handles nil values" do
    map = %{}
    options = Mediasoup.DataProducer.Options.from_map(map)
    assert options.label == nil
    assert options.protocol == nil
    assert options.sctp_stream_parameters == nil
  end
end

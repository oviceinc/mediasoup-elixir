defmodule ConsumerTest do
  use ExUnit.Case

  setup do
    Mediasoup.LoggerProxy.start_link(max_level: :info)
    {:ok, worker} = Mediasoup.Worker.start_link()

    %{worker: worker}
  end

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  test "consume_succeeds", %{worker: worker} do
    IntegrateTest.ConsumerTest.consume_succeeds(worker)
  end

  test "close", %{worker: worker} do
    IntegrateTest.ConsumerTest.close(worker)
  end

  test "consume_incompatible_rtp_capabilities", %{
    worker: worker
  } do
    IntegrateTest.ConsumerTest.consume_incompatible_rtp_capabilities(worker)
  end

  test "dump_succeeds", %{worker: worker} do
    IntegrateTest.ConsumerTest.dump_succeeds(worker)
  end

  test "get_stats_succeeds", %{worker: worker} do
    IntegrateTest.ConsumerTest.get_stats_succeeds(worker)
  end

  test "enable_rtx_option", %{worker: worker} do
    IntegrateTest.ConsumerTest.enable_rtx_option(worker)
  end

  test "pause_resume_succeeds", %{worker: worker} do
    IntegrateTest.ConsumerTest.pause_resume_succeeds(worker)
  end

  test "set_preferred_layers_succeeds", %{
    worker: worker
  } do
    IntegrateTest.ConsumerTest.set_preferred_layers_succeeds(worker)
  end

  test "unset_priority_succeeds", %{worker: worker} do
    IntegrateTest.ConsumerTest.unset_priority_succeeds(worker)
  end

  test "request_key_frame", %{worker: worker} do
    IntegrateTest.ConsumerTest.request_key_frame(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.ConsumerTest.close_event(worker)
  end

  test "payload_events", %{worker: worker} do
    IntegrateTest.ConsumerTest.payload_events(worker)
  end

  test "id/1 returns the correct id", %{worker: worker} do
    {_worker, _router, transport_1, transport_2} = IntegrateTest.ConsumerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ConsumerTest.audio_producer_options()
      )

    {:ok, audio_consumer} =
      Mediasoup.WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: IntegrateTest.ConsumerTest.consumer_device_capabilities()
      })

    assert Mediasoup.Consumer.id(audio_consumer) == audio_consumer.id

    Mediasoup.Consumer.close(audio_consumer)
  end

  test "closed?/1 returns correct status", %{worker: worker} do
    {_worker, _router, transport_1, transport_2} = IntegrateTest.ConsumerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ConsumerTest.audio_producer_options()
      )

    {:ok, audio_consumer} =
      Mediasoup.WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: IntegrateTest.ConsumerTest.consumer_device_capabilities()
      })

    assert Mediasoup.Consumer.closed?(audio_consumer) == false
    Mediasoup.Consumer.close(audio_consumer)
    assert Mediasoup.Consumer.closed?(audio_consumer) == true
  end

  test "kind/1 returns the correct kind", %{worker: worker} do
    {_worker, _router, transport_1, transport_2} = IntegrateTest.ConsumerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ConsumerTest.audio_producer_options()
      )

    {:ok, audio_consumer} =
      Mediasoup.WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: IntegrateTest.ConsumerTest.consumer_device_capabilities()
      })

    assert Mediasoup.Consumer.kind(audio_consumer) == "audio"

    Mediasoup.Consumer.close(audio_consumer)
  end

  test "rtp_parameters/1 returns the correct parameters", %{worker: worker} do
    {_worker, _router, transport_1, transport_2} = IntegrateTest.ConsumerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ConsumerTest.audio_producer_options()
      )

    {:ok, audio_consumer} =
      Mediasoup.WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: IntegrateTest.ConsumerTest.consumer_device_capabilities()
      })

    rtp_parameters = Mediasoup.Consumer.rtp_parameters(audio_consumer)
    assert is_map(rtp_parameters)
    assert Map.has_key?(rtp_parameters, "codecs")

    Mediasoup.Consumer.close(audio_consumer)
  end

  test "type/1 returns the correct type", %{worker: worker} do
    {_worker, _router, transport_1, transport_2} = IntegrateTest.ConsumerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ConsumerTest.audio_producer_options()
      )

    {:ok, audio_consumer} =
      Mediasoup.WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: IntegrateTest.ConsumerTest.consumer_device_capabilities()
      })

    assert Mediasoup.Consumer.type(audio_consumer) == "simple"

    Mediasoup.Consumer.close(audio_consumer)
  end

  test "paused?/1 returns the correct status", %{worker: worker} do
    {_worker, _router, transport_1, transport_2} = IntegrateTest.ConsumerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ConsumerTest.audio_producer_options()
      )

    {:ok, audio_consumer} =
      Mediasoup.WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: IntegrateTest.ConsumerTest.consumer_device_capabilities()
      })

    assert Mediasoup.Consumer.paused?(audio_consumer) == false

    Mediasoup.Consumer.pause(audio_consumer)
    assert Mediasoup.Consumer.paused?(audio_consumer) == true

    Mediasoup.Consumer.resume(audio_consumer)
    assert Mediasoup.Consumer.paused?(audio_consumer) == false

    Mediasoup.Consumer.close(audio_consumer)
  end

  test "producer_paused?/1 returns the correct status", %{worker: worker} do
    {_worker, _router, transport_1, transport_2} = IntegrateTest.ConsumerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ConsumerTest.audio_producer_options()
      )

    {:ok, audio_consumer} =
      Mediasoup.WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: IntegrateTest.ConsumerTest.consumer_device_capabilities()
      })

    assert Mediasoup.Consumer.producer_paused?(audio_consumer) == false

    Mediasoup.Producer.pause(audio_producer)
    # Wait a bit for the state to propagate
    Process.sleep(10)
    assert Mediasoup.Consumer.producer_paused?(audio_consumer) == true

    Mediasoup.Consumer.close(audio_consumer)
  end

  test "struct_from_pid/1 returns the correct struct", %{worker: worker} do
    {_worker, _router, transport_1, transport_2} = IntegrateTest.ConsumerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ConsumerTest.audio_producer_options()
      )

    {:ok, audio_consumer} =
      Mediasoup.WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: IntegrateTest.ConsumerTest.consumer_device_capabilities()
      })

    struct = Mediasoup.Consumer.struct_from_pid(audio_consumer.pid)
    assert struct.id == audio_consumer.id

    Mediasoup.Consumer.close(audio_consumer)
  end

  test "event/3 registers event listener", %{worker: worker} do
    {_worker, _router, transport_1, transport_2} = IntegrateTest.ConsumerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ConsumerTest.audio_producer_options()
      )

    {:ok, audio_consumer} =
      Mediasoup.WebRtcTransport.consume(transport_2, %{
        producerId: audio_producer.id,
        rtpCapabilities: IntegrateTest.ConsumerTest.consumer_device_capabilities()
      })

    assert {:ok} = Mediasoup.Consumer.event(audio_consumer, self(), [:on_close])

    Mediasoup.Consumer.close(audio_consumer)
    assert_receive {:on_close}
  end
end

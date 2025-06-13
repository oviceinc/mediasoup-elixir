defmodule ProducerTest do
  use ExUnit.Case

  setup do
    Mediasoup.LoggerProxy.start_link(max_level: :info)
    {:ok, worker} = Mediasoup.Worker.start_link()

    %{worker: worker}
  end

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  test "produce_succeeds", %{worker: worker} do
    IntegrateTest.ProducerTest.produce_succeeds(worker)
  end

  test "close", %{worker: worker} do
    IntegrateTest.ProducerTest.close(worker)
  end

  test "produce_wrong_arguments", %{worker: worker} do
    IntegrateTest.ProducerTest.produce_wrong_arguments(worker)
  end

  test "produce_unsupported_codecs", %{
    worker: worker
  } do
    IntegrateTest.ProducerTest.produce_unsupported_codecs(worker)
  end

  test "produce_already_used_mid_ssrc", %{
    worker: worker
  } do
    IntegrateTest.ProducerTest.produce_already_used_mid_ssrc(worker)
  end

  test "produce_no_mid_single_encoding_without_dir_or_ssrc", %{
    worker: worker
  } do
    IntegrateTest.ProducerTest.produce_no_mid_single_encoding_without_dir_or_ssrc(worker)
  end

  test "dump_succeeds", %{worker: worker} do
    IntegrateTest.ProducerTest.dump_succeeds(worker)
  end

  test "get_stats_succeeds", %{worker: worker} do
    IntegrateTest.ProducerTest.get_stats_succeeds(worker)
  end

  test "pause_resume_succeeds", %{worker: worker} do
    IntegrateTest.ProducerTest.pause_resume_succeeds(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.ProducerTest.close_event(worker)
  end

  test "producer_event", %{worker: worker} do
    IntegrateTest.ProducerTest.producer_event(worker)
  end

  test "id/1 returns the correct id", %{worker: worker} do
    {_worker, _router, transport_1, _transport_2} = IntegrateTest.ProducerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ProducerTest.audio_producer_options()
      )

    assert Mediasoup.Producer.id(audio_producer) == audio_producer.id

    Mediasoup.Producer.close(audio_producer)
  end

  test "closed?/1 returns correct status", %{worker: worker} do
    {_worker, _router, transport_1, _transport_2} = IntegrateTest.ProducerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ProducerTest.audio_producer_options()
      )

    assert Mediasoup.Producer.closed?(audio_producer) == false
    Mediasoup.Producer.close(audio_producer)
    assert Mediasoup.Producer.closed?(audio_producer) == true
  end

  test "kind/1 returns the correct kind", %{worker: worker} do
    {_worker, _router, transport_1, _transport_2} = IntegrateTest.ProducerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ProducerTest.audio_producer_options()
      )

    assert Mediasoup.Producer.kind(audio_producer) == "audio"

    Mediasoup.Producer.close(audio_producer)
  end

  test "rtp_parameters/1 returns the correct parameters", %{worker: worker} do
    {_worker, _router, transport_1, _transport_2} = IntegrateTest.ProducerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ProducerTest.audio_producer_options()
      )

    rtp_parameters = Mediasoup.Producer.rtp_parameters(audio_producer)
    assert is_map(rtp_parameters)
    assert Map.has_key?(rtp_parameters, "codecs")

    Mediasoup.Producer.close(audio_producer)
  end

  test "type/1 returns the correct type", %{worker: worker} do
    {_worker, _router, transport_1, _transport_2} = IntegrateTest.ProducerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ProducerTest.audio_producer_options()
      )

    assert Mediasoup.Producer.type(audio_producer) == "simple"

    Mediasoup.Producer.close(audio_producer)
  end

  test "paused?/1 returns the correct status", %{worker: worker} do
    {_worker, _router, transport_1, _transport_2} = IntegrateTest.ProducerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ProducerTest.audio_producer_options()
      )

    assert Mediasoup.Producer.paused?(audio_producer) == false

    Mediasoup.Producer.pause(audio_producer)
    assert Mediasoup.Producer.paused?(audio_producer) == true

    Mediasoup.Producer.resume(audio_producer)
    assert Mediasoup.Producer.paused?(audio_producer) == false

    Mediasoup.Producer.close(audio_producer)
  end

  test "struct_from_pid/1 returns the correct struct", %{worker: worker} do
    {_worker, _router, transport_1, _transport_2} = IntegrateTest.ProducerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ProducerTest.audio_producer_options()
      )

    struct = Mediasoup.Producer.struct_from_pid(audio_producer.pid)
    assert struct.id == audio_producer.id

    Mediasoup.Producer.close(audio_producer)
  end

  test "event/3 registers event listener", %{worker: worker} do
    {_worker, _router, transport_1, _transport_2} = IntegrateTest.ProducerTest.init(worker)

    {:ok, audio_producer} =
      Mediasoup.WebRtcTransport.produce(
        transport_1,
        IntegrateTest.ProducerTest.audio_producer_options()
      )

    assert {:ok} = Mediasoup.Producer.event(audio_producer, self(), [:on_close])

    Mediasoup.Producer.close(audio_producer)
    assert_receive {:on_close}
  end
end

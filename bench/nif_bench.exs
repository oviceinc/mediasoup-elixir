# Benchmarks for the NIF boundary (term <-> Rust value conversion and calls).
#
#   MIX_ENV=test mix run bench/nif_bench.exs
#
alias Mediasoup.{Nif, Worker, WebRtcTransport, Producer, Consumer}
alias IntegrateTest.ConsumerTest

{:ok, worker} = Worker.start_link()
{_worker, router, transport_1, transport_2} = ConsumerTest.init(worker)

{:ok, audio_producer} = WebRtcTransport.produce(transport_1, ConsumerTest.audio_producer_options())
{:ok, video_producer} = WebRtcTransport.produce(transport_1, ConsumerTest.video_producer_options())

caps = ConsumerTest.consumer_device_capabilities()

{:ok, video_consumer} =
  WebRtcTransport.consume(transport_2, %{producerId: video_producer.id, rtpCapabilities: caps})

router_ref = :sys.get_state(router.pid).reference
producer_ref = :sys.get_state(video_producer.pid).reference
consumer_ref = :sys.get_state(video_consumer.pid).reference

Benchee.run(
  %{
    "encode: get_supported_rtp_capabilities" => fn ->
      Nif.get_supported_rtp_capabilities()
    end,
    "encode: router_rtp_capabilities" => fn -> Nif.router_rtp_capabilities(router_ref) end,
    "encode: producer_rtp_parameters" => fn -> Nif.producer_rtp_parameters(producer_ref) end,
    "encode: consumer_rtp_parameters" => fn -> Nif.consumer_rtp_parameters(consumer_ref) end,
    "decode: router_can_consume" => fn ->
      true = Nif.router_can_consume(router_ref, video_producer.id, caps)
    end,
    "async: consumer_dump" => fn -> Consumer.dump(video_consumer) end,
    "async: producer_get_stats" => fn -> Producer.get_stats(audio_producer) end,
    "lifecycle: consume + close" => fn ->
      {:ok, consumer} =
        WebRtcTransport.consume(transport_2, %{
          producerId: audio_producer.id,
          rtpCapabilities: caps
        })

      Consumer.close(consumer)
    end
  },
  time: 5,
  warmup: 1,
  memory_time: 0
)

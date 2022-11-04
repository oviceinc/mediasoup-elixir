defmodule IntegrateTest.DataConsumerTest do
  @moduledoc """
  test for DataConsumer with dializer check
  """
  import ExUnit.Assertions
  alias Mediasoup.{WebRtcTransport, DataProducer, Router, DataConsumer, Worker}

  defp data_producer_options() do
    %DataProducer.Options{
      sctp_stream_parameters: %{
        streamId: 0,
        ordered: true
      }
    }
  end

  def init(worker) do
    Worker.event(worker, self())

    {:ok, router} = Worker.create_router(worker, %{})

    {:ok, transport} =
      Router.create_webrtc_transport(router, %{
        listenIps: {
          %{
            ip: "127.0.0.1"
          }
        },
        enableSctp: true
      })

    {worker, router, transport}
  end

  def data_consume_succeeds(worker) do
    {worker, router, transport} = init(worker)
    {:ok, data_producer} = WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      WebRtcTransport.consume_data(transport, %DataConsumer.Options{
        data_producer_id: data_producer |> DataProducer.id(),
        ordered: true
      })

    assert data_producer |> DataProducer.id() === data_consumer |> DataConsumer.data_producer_id()
    assert DataConsumer.type(data_consumer) === "sctp"
    assert DataConsumer.closed?(data_consumer) === false

    assert Router.dump(router)["mapDataProducerIdDataConsumerIds"] === %{
             (data_producer |> DataProducer.id()) => [data_consumer |> DataConsumer.id()]
           }

    assert WebRtcTransport.dump(transport)["dataProducerIds"] === [data_producer.id]
    assert WebRtcTransport.dump(transport)["dataConsumerIds"] === [data_consumer.id]

    DataConsumer.close(data_consumer)
    DataProducer.close(data_producer)
    Router.close(router)
    Worker.close(worker)
  end

  def close(worker) do
    {_worker, _router, transport} = init(worker)
    {:ok, data_producer} = WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      WebRtcTransport.consume_data(transport, %DataConsumer.Options{
        data_producer_id: data_producer |> DataProducer.id(),
        ordered: true
      })

    assert DataConsumer.closed?(data_consumer) === false
    DataConsumer.close(data_consumer)
    assert DataConsumer.closed?(data_consumer) === true
  end

  def sctp_stream_parameters(worker) do
    {_worker, _router, transport} = init(worker)
    {:ok, data_producer} = WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      WebRtcTransport.consume_data(transport, %DataConsumer.Options{
        data_producer_id: data_producer |> DataProducer.id(),
        ordered: true
      })

    assert DataConsumer.sctp_stream_parameters(data_consumer) === %{
             "streamId" => 0,
             "ordered" => true
           }

    DataConsumer.close(data_consumer)
  end

  def label(worker) do
    {_worker, _router, transport} = init(worker)
    {:ok, data_producer} = WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      WebRtcTransport.consume_data(transport, %DataConsumer.Options{
        data_producer_id: data_producer |> DataProducer.id(),
        ordered: true
      })

    assert DataConsumer.label(data_consumer) === ""

    DataConsumer.close(data_consumer)
  end

  def protocol(worker) do
    {_worker, _router, transport} = init(worker)
    {:ok, data_producer} = WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      WebRtcTransport.consume_data(transport, %DataConsumer.Options{
        data_producer_id: data_producer |> DataProducer.id(),
        ordered: true
      })

    assert DataConsumer.protocol(data_consumer) === ""

    DataConsumer.close(data_consumer)
  end

  def close_event(worker) do
    {_worker, _router, transport} = init(worker)
    {:ok, data_producer} = WebRtcTransport.produce_data(transport, data_producer_options())

    {:ok, data_consumer} =
      WebRtcTransport.consume_data(transport, %DataConsumer.Options{
        data_producer_id: data_producer |> DataProducer.id(),
        ordered: true
      })

    DataConsumer.event(data_consumer, self())
    DataConsumer.close(data_consumer)

    assert_receive {:on_close}
  end
end

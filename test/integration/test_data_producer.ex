defmodule IntegrateTest.DataProducerTest do
  @moduledoc """
  test for DataProducer with dializer check
  """
  import ExUnit.Assertions
  alias Mediasoup.{DataProducer, WebRtcTransport, Router}

  defp data_producer_options() do
    %DataProducer.Options{
      sctp_stream_parameters: %{
        streamId: 0,
        ordered: true
      }
    }
  end

  def init(worker) do
    alias Mediasoup.Worker
    Worker.event(worker, self())

    {:ok, router} = Worker.create_router(worker, %{})

    {:ok, transport} =
      Router.create_webrtc_transport(router, %{
        listenIps: [
          %{
            ip: "127.0.0.1"
          }
        ],
        enableSctp: true
      })

    {worker, router, transport}
  end

  def data_produce_succeeds(worker) do
    {_worker, router, transport} = init(worker)

    {:ok, data_producer} = WebRtcTransport.produce_data(transport, data_producer_options())

    assert DataProducer.closed?(data_producer) === false
    assert DataProducer.type(data_producer) === "sctp"
    assert DataProducer.id(data_producer) |> String.length() >= 1

    router_dump = Router.dump(router)

    assert router_dump["mapDataProducerIdDataConsumerIds"] === %{
             data_producer.id => []
           }

    transport_dump = WebRtcTransport.dump(transport)
    assert transport_dump["dataProducerIds"] === [data_producer.id]
    assert transport_dump["consumerIds"] === []
    DataProducer.close(data_producer)
  end

  def close(worker) do
    {_worker, _router, transport} = init(worker)

    {:ok, data_producer} = WebRtcTransport.produce_data(transport, data_producer_options())
    assert DataProducer.closed?(data_producer) === false
    DataProducer.close(data_producer)
    assert DataProducer.closed?(data_producer) === true
  end

  def sctp_stream_parameters(worker) do
    {_worker, _router, transport} = init(worker)

    {:ok, data_producer} = WebRtcTransport.produce_data(transport, data_producer_options())

    assert DataProducer.sctp_stream_parameters(data_producer) === %{
             "streamId" => 0,
             "ordered" => true
           }

    DataProducer.close(data_producer)
  end

  def close_event(worker) do
    {_worker, _router, transport} = init(worker)

    {:ok, data_producer} = WebRtcTransport.produce_data(transport, data_producer_options())

    DataProducer.event(data_producer, self())
    DataProducer.close(data_producer)

    assert_receive {:on_close}
  end
end

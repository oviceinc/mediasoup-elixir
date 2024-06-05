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
end

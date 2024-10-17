defmodule PipeTransportTest do
  use ExUnit.Case

  setup do
    Mediasoup.LoggerProxy.start_link(max_level: :info)
    {:ok, worker} = Mediasoup.Worker.start_link()

    %{worker: worker}
  end

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  test "pipe_to_router_succeeds_with_audio", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_audio(worker)
  end

  test "pipe_to_router_succeeds_with_video", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_video(worker)
  end

  test "pipe_to_router_succeeds_with_data", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_data(worker)
  end

  test "create_with_fixed_port_succeeds", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.create_with_fixed_port_succeeds(worker)
  end

  test "create_with_enable_rtx_succeeds", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.create_with_enable_rtx_succeeds(worker)
  end

  test "create_with_enable_srtp_succeeds", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.create_with_enable_srtp_succeeds(worker)
  end

  test "create_with_invalid_srtp_parameters_fails", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.create_with_invalid_srtp_parameters_fails(worker)
  end

  test "consume_for_pipe_producer_succeeds", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.consume_for_pipe_producer_succeeds(worker)
  end

  test "consume_data_for_pipe_data_producer_succeeds", %{worker: worker} do
    IntegrateTest.PipeTransportTest.consume_data_for_pipe_data_producer_succeeds(worker)
  end

  test "producer_pause_resume_are_transmitted_to_pipe_consumer", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.producer_pause_resume_are_transmitted_to_pipe_consumer(worker)
  end

  test "pipe_to_router_called_twice_generates_single_pair", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.pipe_to_router_called_twice_generates_single_pair(worker)
  end

  test "pipe_produce_consume", %{worker: worker} do
    IntegrateTest.PipeTransportTest.pipe_produce_consume(worker)
  end

  test "pipe_produce_consume_with_map", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.pipe_produce_consume_with_map(worker)
  end

  test "pipe_data_produce_consume", %{worker: worker} do
    IntegrateTest.PipeTransportTest.pipe_data_produce_consume(worker)
  end

  test "multiple_pipe_to_router", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.multiple_pipe_to_router(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.PipeTransportTest.close_event(worker)
  end

  test "close_router_event", %{worker: worker} do
    IntegrateTest.PipeTransportTest.close_router_event(worker)
  end

  test "producer_close_are_transmitted_to_pipe_consumer", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.producer_close_are_transmitted_to_pipe_consumer(worker)
  end

  test "consumer_close_are_transmitted_to_pipe_consumer", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.consumer_close_are_transmitted_to_pipe_consumer(worker)
  end

  test "no_crash_when_exited_pipe_to_router", %{
    worker: worker
  } do
    IntegrateTest.PipeTransportTest.no_crash_when_exited_pipe_to_router(worker)
  end
end

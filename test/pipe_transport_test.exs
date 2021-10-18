defmodule PipeTransportTest do
  use ExUnit.Case

  setup do
    {:ok, struct_worker} = Mediasoup.create_worker()

    {:ok, process_worker} = Mediasoup.Worker.start_link()

    %{struct_worker: struct_worker, process_worker: process_worker}
  end

  test "pipe_to_router_succeeds_with_audio", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_audio(struct_worker)
    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_audio(process_worker)
  end

  test "pipe_to_router_succeeds_with_video", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_video(struct_worker)
    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_video(process_worker)
  end

  test "create_with_fixed_port_succeeds", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.PipeTransportTest.create_with_fixed_port_succeeds(struct_worker)
    IntegrateTest.PipeTransportTest.create_with_fixed_port_succeeds(process_worker)
  end

  test "create_with_enable_rtx_succeeds", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.PipeTransportTest.create_with_enable_rtx_succeeds(struct_worker)
    IntegrateTest.PipeTransportTest.create_with_enable_rtx_succeeds(process_worker)
  end

  test "create_with_enable_srtp_succeeds", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.PipeTransportTest.create_with_enable_srtp_succeeds(struct_worker)
    IntegrateTest.PipeTransportTest.create_with_enable_srtp_succeeds(process_worker)
  end

  test "create_with_invalid_srtp_parameters_fails", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.PipeTransportTest.create_with_invalid_srtp_parameters_fails(struct_worker)
    IntegrateTest.PipeTransportTest.create_with_invalid_srtp_parameters_fails(process_worker)
  end

  test "consume_for_pipe_producer_succeeds", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.PipeTransportTest.consume_for_pipe_producer_succeeds(struct_worker)
    IntegrateTest.PipeTransportTest.consume_for_pipe_producer_succeeds(process_worker)
  end

  test "producer_pause_resume_are_transmitted_to_pipe_consumer", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.PipeTransportTest.producer_pause_resume_are_transmitted_to_pipe_consumer(
      struct_worker
    )

    IntegrateTest.PipeTransportTest.producer_pause_resume_are_transmitted_to_pipe_consumer(
      process_worker
    )
  end

  test "pipe_to_router_called_twice_generates_single_pair", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.PipeTransportTest.pipe_to_router_called_twice_generates_single_pair(
      struct_worker
    )

    IntegrateTest.PipeTransportTest.pipe_to_router_called_twice_generates_single_pair(
      process_worker
    )
  end

  test "pipe_produce_consume", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.PipeTransportTest.pipe_produce_consume(struct_worker)
    IntegrateTest.PipeTransportTest.pipe_produce_consume(process_worker)
  end

  test "pipe_produce_consume_with_map", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.PipeTransportTest.pipe_produce_consume_with_map(struct_worker)
    IntegrateTest.PipeTransportTest.pipe_produce_consume_with_map(process_worker)
  end

  test "close_event", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.PipeTransportTest.close_event(struct_worker)
    IntegrateTest.PipeTransportTest.close_event(process_worker)
  end

  test "close_router_event", %{struct_worker: _struct_worker, process_worker: process_worker} do
    IntegrateTest.PipeTransportTest.close_router_event(process_worker)
  end
end

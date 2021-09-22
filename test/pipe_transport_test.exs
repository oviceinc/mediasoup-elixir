defmodule PipeTransportTest do
  use ExUnit.Case

  test "pipe_to_router_succeeds_with_audio" do
    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_audio()
  end

  test "pipe_to_router_succeeds_with_video" do
    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_video()
  end

  test "create_with_fixed_port_succeeds" do
    IntegrateTest.PipeTransportTest.create_with_fixed_port_succeeds()
  end

  test "create_with_enable_rtx_succeeds" do
    IntegrateTest.PipeTransportTest.create_with_enable_rtx_succeeds()
  end

  test "create_with_enable_srtp_succeeds" do
    IntegrateTest.PipeTransportTest.create_with_enable_srtp_succeeds()
  end

  test "create_with_invalid_srtp_parameters_fails" do
    IntegrateTest.PipeTransportTest.create_with_invalid_srtp_parameters_fails()
  end

  test "consume_for_pipe_producer_succeeds" do
    IntegrateTest.PipeTransportTest.consume_for_pipe_producer_succeeds()
  end

  test "producer_pause_resume_are_transmitted_to_pipe_consumer" do
    IntegrateTest.PipeTransportTest.producer_pause_resume_are_transmitted_to_pipe_consumer()
  end

  test "pipe_to_router_called_twice_generates_single_pair" do
    IntegrateTest.PipeTransportTest.pipe_to_router_called_twice_generates_single_pair()
  end

  test "pipe_produce_consume" do
    IntegrateTest.PipeTransportTest.pipe_produce_consume()
  end

  test "pipe_produce_consume_with_map" do
    IntegrateTest.PipeTransportTest.pipe_produce_consume_with_map()
  end
end

defmodule PipeTransportTest do
  use ExUnit.Case

  test "pipe_to_router_succeeds_with_audio" do
    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_audio()
  end

  test "pipe_to_router_succeeds_with_video" do
    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_video()
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
end

defmodule ConsumerTest do
  use ExUnit.Case

  test "consume_succeeds" do
    IntegrateTest.ConsumerTest.consume_succeeds()
  end

  test "close" do
    IntegrateTest.ConsumerTest.close()
  end

  test "consume_incompatible_rtp_capabilities" do
    IntegrateTest.ConsumerTest.consume_incompatible_rtp_capabilities()
  end

  test "dump_succeeds" do
    IntegrateTest.ConsumerTest.dump_succeeds()
  end

  test "get_stats_succeeds" do
    IntegrateTest.ConsumerTest.get_stats_succeeds()
  end

  test "pause_resume_succeeds" do
    IntegrateTest.ConsumerTest.pause_resume_succeeds()
  end

  test "set_preferred_layers_succeeds" do
    IntegrateTest.ConsumerTest.set_preferred_layers_succeeds()
  end

  test "unset_priority_succeeds" do
    IntegrateTest.ConsumerTest.unset_priority_succeeds()
  end

  test "request_key_frame" do
    IntegrateTest.ConsumerTest.request_key_frame()
  end

  test "close_event" do
    IntegrateTest.ConsumerTest.close_event()
  end
end

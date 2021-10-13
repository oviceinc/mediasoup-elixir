defmodule ConsumerTest do
  use ExUnit.Case

  setup do
    {:ok, struct_worker} = Mediasoup.create_worker()

    {:ok, process_worker} = Mediasoup.Worker.start_link()

    %{struct_worker: struct_worker, process_worker: process_worker}
  end

  test "consume_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ConsumerTest.consume_succeeds(struct_worker)
    IntegrateTest.ConsumerTest.consume_succeeds(process_worker)
  end

  test "close", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ConsumerTest.close(struct_worker)
    IntegrateTest.ConsumerTest.close(process_worker)
  end

  test "consume_incompatible_rtp_capabilities", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.ConsumerTest.consume_incompatible_rtp_capabilities(struct_worker)
    IntegrateTest.ConsumerTest.consume_incompatible_rtp_capabilities(process_worker)
  end

  test "dump_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ConsumerTest.dump_succeeds(struct_worker)
    IntegrateTest.ConsumerTest.dump_succeeds(process_worker)
  end

  test "get_stats_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ConsumerTest.get_stats_succeeds(struct_worker)
    IntegrateTest.ConsumerTest.get_stats_succeeds(process_worker)
  end

  test "pause_resume_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ConsumerTest.pause_resume_succeeds(struct_worker)
    IntegrateTest.ConsumerTest.pause_resume_succeeds(process_worker)
  end

  test "set_preferred_layers_succeeds", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.ConsumerTest.set_preferred_layers_succeeds(struct_worker)
    IntegrateTest.ConsumerTest.set_preferred_layers_succeeds(process_worker)
  end

  test "unset_priority_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ConsumerTest.unset_priority_succeeds(struct_worker)
    IntegrateTest.ConsumerTest.unset_priority_succeeds(process_worker)
  end

  test "request_key_frame", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ConsumerTest.request_key_frame(struct_worker)
    IntegrateTest.ConsumerTest.request_key_frame(process_worker)
  end

  test "close_event", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ConsumerTest.close_event(struct_worker)
    IntegrateTest.ConsumerTest.close_event(process_worker)
  end
end

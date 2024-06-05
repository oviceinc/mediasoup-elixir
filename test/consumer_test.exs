defmodule ConsumerTest do
  use ExUnit.Case

  setup do
    children = [
      {Mediasoup.LoggerProxy, max_level: :info}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ConsumerTest.Supervisor)
    {:ok, worker} = Mediasoup.Worker.start_link()

    %{worker: worker}
  end

  import Mediasoup.TestUtil
  setup_all :worker_leak_setup_all
  setup :verify_worker_leak_on_exit!

  test "consume_succeeds", %{worker: worker} do
    IntegrateTest.ConsumerTest.consume_succeeds(worker)
  end

  test "close", %{worker: worker} do
    IntegrateTest.ConsumerTest.close(worker)
  end

  test "consume_incompatible_rtp_capabilities", %{
    worker: worker
  } do
    IntegrateTest.ConsumerTest.consume_incompatible_rtp_capabilities(worker)
  end

  test "dump_succeeds", %{worker: worker} do
    IntegrateTest.ConsumerTest.dump_succeeds(worker)
  end

  test "get_stats_succeeds", %{worker: worker} do
    IntegrateTest.ConsumerTest.get_stats_succeeds(worker)
  end

  test "enable_rtx_option", %{worker: worker} do
    IntegrateTest.ConsumerTest.enable_rtx_option(worker)
  end

  test "pause_resume_succeeds", %{worker: worker} do
    IntegrateTest.ConsumerTest.pause_resume_succeeds(worker)
  end

  test "set_preferred_layers_succeeds", %{
    worker: worker
  } do
    IntegrateTest.ConsumerTest.set_preferred_layers_succeeds(worker)
  end

  test "unset_priority_succeeds", %{worker: worker} do
    IntegrateTest.ConsumerTest.unset_priority_succeeds(worker)
  end

  test "request_key_frame", %{worker: worker} do
    IntegrateTest.ConsumerTest.request_key_frame(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.ConsumerTest.close_event(worker)
  end
end

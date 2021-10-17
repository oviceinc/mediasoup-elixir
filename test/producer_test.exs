defmodule ProducerTest do
  use ExUnit.Case

  setup do
    {:ok, struct_worker} = Mediasoup.create_worker()

    {:ok, process_worker} = Mediasoup.Worker.start_link()

    %{struct_worker: struct_worker, process_worker: process_worker}
  end

  test "produce_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ProducerTest.produce_succeeds(struct_worker)
    IntegrateTest.ProducerTest.produce_succeeds(process_worker)
  end

  test "close", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ProducerTest.close(struct_worker)
    IntegrateTest.ProducerTest.close(process_worker)
  end

  test "produce_wrong_arguments", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ProducerTest.produce_wrong_arguments(struct_worker)
    IntegrateTest.ProducerTest.produce_wrong_arguments(process_worker)
  end

  test "produce_unsupported_codecs", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.ProducerTest.produce_unsupported_codecs(struct_worker)
    IntegrateTest.ProducerTest.produce_unsupported_codecs(process_worker)
  end

  test "produce_already_used_mid_ssrc", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.ProducerTest.produce_already_used_mid_ssrc(struct_worker)
    IntegrateTest.ProducerTest.produce_already_used_mid_ssrc(process_worker)
  end

  test "produce_no_mid_single_encoding_without_dir_or_ssrc", %{
    struct_worker: struct_worker,
    process_worker: process_worker
  } do
    IntegrateTest.ProducerTest.produce_no_mid_single_encoding_without_dir_or_ssrc(struct_worker)
    IntegrateTest.ProducerTest.produce_no_mid_single_encoding_without_dir_or_ssrc(process_worker)
  end

  test "dump_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ProducerTest.dump_succeeds(struct_worker)
    IntegrateTest.ProducerTest.dump_succeeds(process_worker)
  end

  test "get_stats_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ProducerTest.get_stats_succeeds(struct_worker)
    IntegrateTest.ProducerTest.get_stats_succeeds(process_worker)
  end

  test "pause_resume_succeeds", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ProducerTest.pause_resume_succeeds(struct_worker)
    IntegrateTest.ProducerTest.pause_resume_succeeds(process_worker)
  end

  test "close_event", %{struct_worker: struct_worker, process_worker: process_worker} do
    IntegrateTest.ProducerTest.close_event(struct_worker)
    IntegrateTest.ProducerTest.close_event(process_worker)
  end
end

defmodule ProducerTest do
  use ExUnit.Case

  setup do
    {:ok, worker} = Mediasoup.Worker.start_link()

    %{worker: worker}
  end

  test "produce_succeeds", %{worker: worker} do
    IntegrateTest.ProducerTest.produce_succeeds(worker)
  end

  test "close", %{worker: worker} do
    IntegrateTest.ProducerTest.close(worker)
  end

  test "produce_wrong_arguments", %{worker: worker} do
    IntegrateTest.ProducerTest.produce_wrong_arguments(worker)
  end

  test "produce_unsupported_codecs", %{
    worker: worker
  } do
    IntegrateTest.ProducerTest.produce_unsupported_codecs(worker)
  end

  test "produce_already_used_mid_ssrc", %{
    worker: worker
  } do
    IntegrateTest.ProducerTest.produce_already_used_mid_ssrc(worker)
  end

  test "produce_no_mid_single_encoding_without_dir_or_ssrc", %{
    worker: worker
  } do
    IntegrateTest.ProducerTest.produce_no_mid_single_encoding_without_dir_or_ssrc(worker)
  end

  test "dump_succeeds", %{worker: worker} do
    IntegrateTest.ProducerTest.dump_succeeds(worker)
  end

  test "get_stats_succeeds", %{worker: worker} do
    IntegrateTest.ProducerTest.get_stats_succeeds(worker)
  end

  test "pause_resume_succeeds", %{worker: worker} do
    IntegrateTest.ProducerTest.pause_resume_succeeds(worker)
  end

  test "close_event", %{worker: worker} do
    IntegrateTest.ProducerTest.close_event(worker)
  end
end

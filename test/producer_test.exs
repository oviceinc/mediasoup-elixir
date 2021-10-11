defmodule ProducerTest do
  use ExUnit.Case

  test "produce_succeeds" do
    IntegrateTest.ProducerTest.produce_succeeds()
  end

  test "close" do
    IntegrateTest.ProducerTest.close()
  end

  test "produce_wrong_arguments" do
    IntegrateTest.ProducerTest.produce_wrong_arguments()
  end

  test "produce_unsupported_codecs" do
    IntegrateTest.ProducerTest.produce_unsupported_codecs()
  end

  test "produce_already_used_mid_ssrc" do
    IntegrateTest.ProducerTest.produce_already_used_mid_ssrc()
  end

  test "produce_no_mid_single_encoding_without_dir_or_ssrc" do
    IntegrateTest.ProducerTest.produce_no_mid_single_encoding_without_dir_or_ssrc()
  end

  test "dump_succeeds" do
    IntegrateTest.ProducerTest.dump_succeeds()
  end

  test "get_stats_succeeds" do
    IntegrateTest.ProducerTest.get_stats_succeeds()
  end

  test "pause_resume_succeeds" do
    IntegrateTest.ProducerTest.pause_resume_succeeds()
  end

  test "close_event" do
    IntegrateTest.ProducerTest.close_event()
  end
end

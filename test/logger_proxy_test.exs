defmodule Mediasoup.LoggerProxyTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Mediasoup.LoggerProxy

  test "max_level off " do
    LoggerProxy.start_link(max_level: :off)

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:error, "test")
             Process.sleep(10)
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:warn, "test")
             Process.sleep(10)
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:info, "test")
             Process.sleep(10)
           end) =~ "test"
  end

  test "max_level error " do
    LoggerProxy.start_link(max_level: :error)

    assert capture_log(fn ->
             Mediasoup.Nif.debug_logger(:error, "test")
             Process.sleep(10)
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:warn, "test")
             Process.sleep(10)
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:warn, "test")
             Process.sleep(10)
           end) =~ "test"
  end

  test " max_level warn" do
    LoggerProxy.start_link(max_level: :warn)

    assert capture_log(fn ->
             Mediasoup.Nif.debug_logger(:warn, "test")
             Process.sleep(10)
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:info, "test")
             Process.sleep(10)
           end) =~ "test"
  end

  test " max_level info" do
    LoggerProxy.start_link(max_level: :info)

    assert capture_log(fn ->
             Mediasoup.Nif.debug_logger(:info, "test")
             Process.sleep(10)
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:debug, "test")
             Process.sleep(10)
           end) =~ "test"
  end

  test " max_level debug" do
    LoggerProxy.start_link(max_level: :debug)

    assert capture_log(fn ->
             Mediasoup.Nif.debug_logger(:info, "test")
             Process.sleep(10)
           end) =~ "test"

    assert capture_log(fn ->
             Mediasoup.Nif.debug_logger(:debug, "test")
             Process.sleep(10)
           end) =~ "test"
  end

  describe "log filter" do
    test "filter info only" do
      LoggerProxy.start_link(max_level: :debug, filter: fn msg -> msg.level == :info end)

      assert capture_log(fn ->
               Mediasoup.Nif.debug_logger(:info, "test")
               Process.sleep(10)
             end) =~ "test"

      refute capture_log(fn ->
               Mediasoup.Nif.debug_logger(:debug, "test")
               Process.sleep(10)
             end) =~ "test"
    end

    test "filter can_consume error" do
      pattern = ~r/can_consume\(\) \| Producer with id "(?<id>[^"]+)" not found/

      filter_can_consume_error = fn msg ->
        msg.level === :error && msg.target === "mediasoup::router" &&
          Regex.match?(pattern, msg.body)
      end

      LoggerProxy.start_link(
        max_level: :warn,
        filter: filter_can_consume_error
      )

      alias Mediasoup.{Worker, Router}
      {:ok, worker} = Worker.start_link()

      {:ok, router} =
        Worker.create_router(worker, %{
          mediaCodecs: []
        })

      assert capture_log(fn ->
               Router.can_consume?(router, "d117b485-7490-4146-812f-d3f744f0a8c7", %{
                 codecs: [],
                 headerExtensions: [],
                 fecMechanisms: []
               })

               Process.sleep(10)
             end) =~ "can_consume() | Producer with id "
    end
  end
end

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

    test "filter out can_consume error" do
      pattern = ~r/can_consume\(\) \| Producer with id "(?<id>[^"]+)" not found/

      LoggerProxy.start_link(
        max_level: :warn,
        filters: [
          fn record ->
            if msg.level === :error && msg.target === "mediasoup::router" &&
                 Regex.match?(pattern, msg.body) do
              :stop
            else
              :ignore
            end
          end
        ]
      )

      alias Mediasoup.{Worker, Router}
      {:ok, worker} = Worker.start_link()

      {:ok, router} =
        Worker.create_router(worker, %{
          mediaCodecs: []
        })

      refute capture_log(fn ->
               Router.can_consume?(router, "d117b485-7490-4146-812f-d3f744f0a8c7", %{
                 codecs: [],
                 headerExtensions: [],
                 fecMechanisms: []
               })

               Process.sleep(10)
             end) =~ "can_consume() | Producer with id "
    end

    test "multiple filters" do
      LoggerProxy.start_link(
        max_level: :debug,
        filters: [
          fn msg -> msg.level in [:error, :warn] end,
          fn msg -> String.contains?(msg.body, "important") end
        ]
      )

      assert capture_log(fn ->
               Mediasoup.Nif.debug_logger(:error, "important message")
               Process.sleep(10)
             end) =~ "important message"

      refute capture_log(fn ->
               Mediasoup.Nif.debug_logger(:error, "normal message")
               Process.sleep(10)
             end) =~ "normal message"

      refute capture_log(fn ->
               Mediasoup.Nif.debug_logger(:info, "important message")
               Process.sleep(10)
             end) =~ "important message"
    end

    test "filter by target pattern" do
      target_pattern = ~r/^mediasoup::worker/

      LoggerProxy.start_link(
        max_level: :debug,
        filters: [
          fn msg ->
            Regex.match?(target_pattern, msg.target)
          end
        ]
      )

      assert capture_log(fn ->
               Mediasoup.Nif.debug_logger(:info, "test", "mediasoup::worker")
               Process.sleep(10)
             end) =~ "test"

      refute capture_log(fn ->
               Mediasoup.Nif.debug_logger(:info, "test", "mediasoup::router")
               Process.sleep(10)
             end) =~ "test"
    end
  end
end

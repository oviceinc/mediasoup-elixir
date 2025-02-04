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
    test "filter debug message" do
      LoggerProxy.start_link(
        max_level: :debug,
        filters: [
          fn msg ->
            case msg.level do
              :debug -> :stop
              _ -> :ignore
            end
          end
        ]
      )

      assert capture_log(fn ->
               Mediasoup.Nif.debug_logger(:info, "test")
               Process.sleep(10)
             end) =~ "test"

      refute capture_log(fn ->
               Mediasoup.Nif.debug_logger(:debug, "test")
               Process.sleep(10)
             end) =~ "test"
    end

    test "can_consume error should be warn" do
      pattern = ~r/can_consume\(\) \| Producer with id "(?<id>[^"]+)" not found/

      filter_can_consume_error = fn msg ->
        if msg.level === :error && msg.target === "mediasoup::router" &&
             Regex.match?(pattern, msg.body) do
          {:log, Map.put(msg, :level, :warn)}
        else
          :ignore
        end
      end

      LoggerProxy.start_link(
        max_level: :warn,
        filters: [filter_can_consume_error]
      )

      alias Mediasoup.{Worker, Router}
      {:ok, worker} = Worker.start_link()

      {:ok, router} =
        Worker.create_router(worker, %{
          mediaCodecs: []
        })

      assert capture_log([level: :warn], fn ->
               Router.can_consume?(router, "d117b485-7490-4146-812f-d3f744f0a8c7", %{
                 codecs: [],
                 headerExtensions: [],
                 fecMechanisms: []
               })

               Process.sleep(10)
             end) =~ "can_consume() | Producer with id "

      refute capture_log([level: :error], fn ->
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
          fn msg ->
            if Regex.match?(~r/should be logged/, msg.body) do
              :log
            else
              :ignore
            end
          end,
          fn msg ->
            if msg.level === :debug && Regex.match?(~r/test/, msg.body) do
              {:log, Map.put(msg, :level, :info)}
            else
              :ignore
            end
          end,
          fn msg ->
            if msg.level === :warn && Regex.match?(~r/test/, msg.body) do
              :stop
            else
              :ignore
            end
          end
        ]
      )

      assert capture_log([level: :info], fn ->
               Mediasoup.Nif.debug_logger(:debug, "debug test")
               Mediasoup.Nif.debug_logger(:warn, "warn test")
               Process.sleep(10)
             end) =~ "debug test"

      refute capture_log(fn ->
               Mediasoup.Nif.debug_logger(:info, "info test")
               Mediasoup.Nif.debug_logger(:warn, "warn test")
               Process.sleep(10)
             end) =~ "warn test"

      assert capture_log(fn ->
               Mediasoup.Nif.debug_logger(:warn, "warn test")
               Mediasoup.Nif.debug_logger(:info, "should be logged")
               Process.sleep(10)
             end) =~ "should be logged"
    end
  end
end

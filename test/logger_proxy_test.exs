defmodule Mediasoup.LoggerProxyTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Mediasoup.LoggerProxy

  # Records are sent from the NIF asynchronously, so tests wait for the proxy to
  # receive them instead of sleeping.
  @receive_timeout 1_000
  # How long to wait for a record that must not reach the proxy.
  @refute_timeout 50

  # LoggerProxy is registered under a fixed name, and one started with
  # start_link by an earlier test may still be shutting down. Stop it before
  # starting ours, otherwise start would fail and the NIF would keep the old
  # process and max_level.
  defp start_logger_proxy(config) do
    case Process.whereis(LoggerProxy) do
      nil ->
        :ok

      pid ->
        ref = Process.monitor(pid)
        Process.exit(pid, :kill)
        assert_receive {:DOWN, ^ref, :process, ^pid, _}, @receive_timeout
    end

    test_pid = self()

    notify = fn msg ->
      send(test_pid, {:logger_proxy_received, msg.body})
      :ignore
    end

    start_supervised!({LoggerProxy, Keyword.update(config, :filters, [notify], &[notify | &1])})
  end

  # Waits until the proxy has received and handled a record whose body matches.
  # Records are not guaranteed to arrive in the order they were logged.
  defp await_proxy_log(%Regex{} = pattern) do
    receive do
      {:logger_proxy_received, body} ->
        if Regex.match?(pattern, body), do: sync_proxy(), else: await_proxy_log(pattern)
    after
      @receive_timeout -> flunk("LoggerProxy did not receive #{inspect(pattern)}")
    end
  end

  defp await_proxy_log(body) do
    assert_receive {:logger_proxy_received, ^body}, @receive_timeout
    sync_proxy()
  end

  # Ensures handle_info has finished, i.e. Logger.log has been called.
  defp sync_proxy, do: :sys.get_state(LoggerProxy)

  defp refute_proxy_log(body) do
    refute_receive {:logger_proxy_received, ^body}, @refute_timeout
  end

  test "max_level off " do
    start_logger_proxy(max_level: :off)

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:error, "test")
             refute_proxy_log("test")
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:warn, "test")
             refute_proxy_log("test")
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:info, "test")
             refute_proxy_log("test")
           end) =~ "test"
  end

  test "max_level error " do
    start_logger_proxy(max_level: :error)

    assert capture_log(fn ->
             Mediasoup.Nif.debug_logger(:error, "test")
             await_proxy_log("test")
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:warn, "test")
             refute_proxy_log("test")
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:warn, "test")
             refute_proxy_log("test")
           end) =~ "test"
  end

  test " max_level warn" do
    start_logger_proxy(max_level: :warn)

    assert capture_log(fn ->
             Mediasoup.Nif.debug_logger(:warn, "test")
             await_proxy_log("test")
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:info, "test")
             refute_proxy_log("test")
           end) =~ "test"
  end

  test " max_level info" do
    start_logger_proxy(max_level: :info)

    assert capture_log(fn ->
             Mediasoup.Nif.debug_logger(:info, "test")
             await_proxy_log("test")
           end) =~ "test"

    refute capture_log(fn ->
             Mediasoup.Nif.debug_logger(:debug, "test")
             refute_proxy_log("test")
           end) =~ "test"
  end

  test " max_level debug" do
    start_logger_proxy(max_level: :debug)

    assert capture_log(fn ->
             Mediasoup.Nif.debug_logger(:info, "test")
             await_proxy_log("test")
           end) =~ "test"

    assert capture_log(fn ->
             Mediasoup.Nif.debug_logger(:debug, "test")
             await_proxy_log("test")
           end) =~ "test"
  end

  describe "log filter" do
    test "filter debug message" do
      start_logger_proxy(
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
               await_proxy_log("test")
             end) =~ "test"

      refute capture_log(fn ->
               Mediasoup.Nif.debug_logger(:debug, "test")
               await_proxy_log("test")
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

      start_logger_proxy(
        max_level: :warn,
        filters: [filter_can_consume_error]
      )

      alias Mediasoup.{Worker, Router}
      {:ok, worker} = Worker.start_link()

      {:ok, router} =
        Worker.create_router(worker, %{
          mediaCodecs: []
        })

      assert capture_log([level: :warning], fn ->
               Router.can_consume?(router, "d117b485-7490-4146-812f-d3f744f0a8c7", %{
                 codecs: [],
                 headerExtensions: [],
                 fecMechanisms: []
               })

               await_proxy_log(pattern)
             end) =~ "can_consume() | Producer with id "

      refute capture_log([level: :error], fn ->
               Router.can_consume?(router, "d117b485-7490-4146-812f-d3f744f0a8c7", %{
                 codecs: [],
                 headerExtensions: [],
                 fecMechanisms: []
               })

               await_proxy_log(pattern)
             end) =~ "can_consume() | Producer with id "
    end

    test "multiple filters" do
      start_logger_proxy(
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
               await_proxy_log("debug test")
               await_proxy_log("warn test")
             end) =~ "debug test"

      refute capture_log(fn ->
               Mediasoup.Nif.debug_logger(:info, "info test")
               Mediasoup.Nif.debug_logger(:warn, "warn test")
               await_proxy_log("info test")
               await_proxy_log("warn test")
             end) =~ "warn test"

      assert capture_log(fn ->
               Mediasoup.Nif.debug_logger(:warn, "warn test")
               Mediasoup.Nif.debug_logger(:info, "should be logged")
               await_proxy_log("warn test")
               await_proxy_log("should be logged")
             end) =~ "should be logged"
    end
  end
end

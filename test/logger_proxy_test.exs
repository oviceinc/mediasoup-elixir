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
end

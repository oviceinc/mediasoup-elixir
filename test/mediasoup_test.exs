defmodule MediasoupTest do
  use ExUnit.Case

  test "version/0 returns version string" do
    version = Mediasoup.version()
    assert is_binary(version)
    assert String.match?(version, ~r/^\d+\.\d+\.\d+$/)
  end

  test "init_env_logger/0 can be called" do
    # This function may fail if logger is already initialized, but should not crash
    try do
      Mediasoup.init_env_logger()
    catch
      :error, :nif_panicked -> :ok
    end
  end
end

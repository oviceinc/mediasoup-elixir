defmodule MediasoupTest do
  use ExUnit.Case

  test "version/0 returns the version string" do
    version = Mediasoup.version()
    assert is_binary(version)
    assert String.length(version) > 0
  end

  # test "init_env_logger/0 does not raise" do
  #   assert :ok == Mediasoup.init_env_logger()
  # end
end

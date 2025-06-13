defmodule MediasoupTest do
  use ExUnit.Case

  test "version/0 returns version string" do
    version = Mediasoup.version()
    assert is_binary(version)
    assert String.match?(version, ~r/^\d+\.\d+\.\d+$/)
  end
end

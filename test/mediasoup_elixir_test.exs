defmodule MediasoupElixirTest do
  use ExUnit.Case
  doctest Mediasoup

  test "create_worker" do
    assert Mediasoup.create_worker()
  end

  test "create_worker with option" do
    assert Mediasoup.create_worker(%{
             rtcMinPort: 10000,
             rtcMaxPort: 10010,
             logLevel: :debug
           })
  end
end

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

  test "get_remote_node_ip" do
    assert match?({:ok, _ip}, Mediasoup.Utility.get_remote_node_ip(Node.self(), Node.self()))
  end

  test "get_remote_node_ip_different_node" do
    assert match?(
             {:ok, _ip},
             Mediasoup.Utility.get_remote_node_ip_different_node(Node.self(), Node.self())
           )
  end
end

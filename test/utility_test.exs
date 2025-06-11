defmodule Mediasoup.UtilityTest do
  use ExUnit.Case

  test "get_listen_ip/2 returns 127.0.0.1 when nodes are the same" do
    node = Node.self()
    assert {:ok, "127.0.0.1"} == Mediasoup.Utility.get_listen_ip(node, node)
  end

  test "get_listen_ip/2 returns 0.0.0.0 when nodes are different" do
    node1 = :node1@localhost
    node2 = :node2@localhost
    assert {:ok, "0.0.0.0"} == Mediasoup.Utility.get_listen_ip(node1, node2)
  end
end

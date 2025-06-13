defmodule SmokeTest do
  use ExUnit.Case

  test "version" do
    IntegrateTest.SmokeTest.version()
  end

  test "utility get_listen_ip and get_remote_node_ip" do
    node = Node.self()
    # get_listen_ip: same node
    assert Mediasoup.Utility.get_listen_ip(node, node) == {:ok, "127.0.0.1"}
    # get_listen_ip: different node
    assert Mediasoup.Utility.get_listen_ip(node, :other@host) == {:ok, "0.0.0.0"}
    # get_remote_node_ip: same node
    assert Mediasoup.Utility.get_remote_node_ip(node, node) == {:ok, "127.0.0.1"}
  end
end

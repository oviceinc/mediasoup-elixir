defmodule Mediasoup.UtilityTest do
  use ExUnit.Case

  test "get_remote_node_ip/2 returns correct IP for local node" do
    assert {:ok, "127.0.0.1"} = Mediasoup.Utility.get_remote_node_ip(Node.self(), Node.self())
  end

  test "get_remote_node_ip/2 returns error for non-existent node" do
    assert {:badrpc, :nodedown} =
             Mediasoup.Utility.get_remote_node_ip(Node.self(), :nonexistent@localhost)
  end

  test "get_listen_ip/2 returns correct IP for local node" do
    assert {:ok, "127.0.0.1"} = Mediasoup.Utility.get_listen_ip(Node.self(), Node.self())
  end

  test "get_listen_ip/2 returns 0.0.0.0 for remote node" do
    assert {:ok, "0.0.0.0"} = Mediasoup.Utility.get_listen_ip(Node.self(), :nonexistent@localhost)
  end

  test "get_remote_node_ip_different_node/1 returns error for non-existent node" do
    assert {:badrpc, :nodedown} =
             Mediasoup.Utility.get_remote_node_ip_different_node(:nonexistent@localhost)
  end

  test "get_remote_node_ip_different_node/2 returns error for non-existent node" do
    assert {:badrpc, :nodedown} =
             Mediasoup.Utility.get_remote_node_ip_different_node(
               Node.self(),
               :nonexistent@localhost
             )
  end
end

defmodule Mediasoup.EventListenerTest do
  use ExUnit.Case

  test "new/0 creates empty event listener" do
    listener = Mediasoup.EventListener.new()
    assert %Mediasoup.EventListener{listeners: %{}} = listener
  end

  test "add/3 adds listener" do
    listener = Mediasoup.EventListener.new()
    listener = Mediasoup.EventListener.add(listener, self(), [:on_close])
    assert Map.has_key?(listener.listeners, self())
  end

  test "remove/2 removes listener" do
    listener = Mediasoup.EventListener.new()
    listener = Mediasoup.EventListener.add(listener, self(), [:on_close])
    listener = Mediasoup.EventListener.remove(listener, self())
    assert not Map.has_key?(listener.listeners, self())
  end

  test "send/3 sends message to listeners" do
    listener = Mediasoup.EventListener.new()
    listener = Mediasoup.EventListener.add(listener, self(), [:on_close])
    Mediasoup.EventListener.send(listener, :on_close, {:on_close})
    assert_receive {:on_close}
  end

  test "send/3 does not send message for unregistered events" do
    listener = Mediasoup.EventListener.new()
    listener = Mediasoup.EventListener.add(listener, self(), [:on_pause])
    Mediasoup.EventListener.send(listener, :on_close, {:on_close})
    refute_receive {:on_close}, 100
  end

  test "add/3 updates existing listener event types" do
    listener = Mediasoup.EventListener.new()
    listener = Mediasoup.EventListener.add(listener, self(), [:on_close])
    listener = Mediasoup.EventListener.add(listener, self(), [:on_pause])

    # Should have updated event types
    assert listener.listeners[self()].event_types == [:on_pause]
  end
end

defmodule ClusterTest do
  use ExUnit.Case

  setup_all do
    nodes =
      LocalCluster.start_nodes(:spawn, 1,
        files: [
          __ENV__.file
        ]
      )

    %{nodes: nodes}
  end

  @tag :cluster
  test "pipe_to_router_succeeds_with_audio ", %{nodes: [node1]} do
    caller = self()

    Node.spawn(node1, fn ->
      send(caller, Mediasoup.Worker.start_link())
      Process.sleep(50000)
    end)

    worker =
      receive do
        {:ok, worker} -> worker
      end

    IntegrateTest.PipeTransportTest.pipe_to_router_succeeds_with_audio(worker)
  end

  @tag :cluster
  test "get_remote_node_ip", %{nodes: [node1]} do
    {:ok, remote_ip} = Mediasoup.Utility.get_remote_node_ip(Node.self(), node1)
    refute remote_ip == "127.0.0.1"
  end
end

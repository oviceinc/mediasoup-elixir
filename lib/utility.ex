defmodule Mediasoup.Utility do
  @moduledoc """
  Utilities
  """

  @doc false
  def get_remote_node_ip_different_node(to_node) do
    gethostresult = :rpc.call(to_node, :inet, :gethostname, [], 5000)

    with {:ok, hostname} <- gethostresult,
         {:ok, ip} <- :inet.getaddr(hostname, :inet) do
      {:ok, to_string(:inet.ntoa(ip))}
    end
  end

  @doc false
  def get_remote_node_ip_different_node(from_node, to_node) do
    :rpc.call(from_node, Mediasoup.Utility, :get_remote_node_ip_different_node, [to_node], 5000)
  end

  @spec get_remote_node_ip(node(), node()) ::
          {:ok, ipaddress :: String.t()} | {:error, reason :: term}
  def get_remote_node_ip(from_node, to_node) when from_node == to_node do
    {:ok, "127.0.0.1"}
  end

  @doc """
  Get local ip from nodes.
  used in Router.pipe_producer_to_router for default implementation.

  Returns `{:ok, ipaddress} | {:error, reason}`.

  1. execute gethostname on remote(connection to) node
  2. execute getaddr by hostname on local(connection from) node
  """
  def get_remote_node_ip(from_node, to_node) do
    get_remote_node_ip_different_node(from_node, to_node)
  end

  @doc """
  Get listen ip from nodes.
  used in Router.pipe_producer_to_router for default implementation.

  Returns `{:ok, ipaddress}`.
  When from_node and to_node is same, return {:ok, "127.0.0.1"}, Otherwise return {:ok, "0.0.0.0"}

  """
  def get_listen_ip(from_node, to_node) when from_node == to_node do
    {:ok, "127.0.0.1"}
  end

  def get_listen_ip(_from_node, _to_node) do
    {:ok, "0.0.0.0"}
  end
end

defmodule Mediasoup do
  @moduledoc """
  Documentation for `Mediasoup`.
  """
  alias Mediasoup.{Worker, Nif}

  @spec create_worker() :: {:ok, Worker.t()} | {:error, String.t()}
  def create_worker() do
    Nif.create_worker()
  end

  @spec create_worker(Worker.Settings.t() | Worker.create_option()) ::
          {:ok, Worker.t()} | {:error, String.t()}
  def create_worker(%Worker.Settings{} = settings) do
    Nif.create_worker(settings)
  end

  def create_worker(option) do
    Nif.create_worker(Worker.Settings.from_map(option))
  end

  @type num_sctp_streams :: %{OS: integer(), MIS: integer()}
  @type transport_listen_ip :: %{:ip => String.t(), optional(:announcedIp) => String.t() | nil}

  def get_remote_node_ip(to_node) do
    from = self()

    Node.spawn_link(to_node, fn ->
      send(from, {:gethost, :inet.gethostname()})
    end)

    gethostresult =
      receive do
        {:gethost, result} -> result
      after
        5000 ->
          {:error, "timeout: gethostname"}
      end

    with {:ok, hostname} <- gethostresult,
         {:ok, ip} <- :inet.getaddr(hostname, :inet) do
      {:ok, to_string(:inet.ntoa(ip))}
    end
  end

  @doc """
  Get local ip from node.
  used in Router.pipe_producer_to_router for default implementation.

  Returns `{:ok, ipaddress} | {:error, reason}`.

  1. execute gethostname on remote(connection to) node
  2. execute getaddr by hostname on local(connection from) node
  """
  def get_remote_node_ip(from_node, to_node) do
    from = self()

    Node.spawn_link(from_node, fn ->
      node_ip = get_remote_node_ip(to_node)
      send(from, {:get_remote_node_ip, node_ip})
    end)

    receive do
      {:get_remote_node_ip, result} -> result
    after
      5000 ->
        {:error, "timeout: get_remote_node_ip"}
    end
  end
end

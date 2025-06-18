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

defmodule Mediasoup.EventListener do
  @moduledoc """
  Event listener module for rustler because rustler(nif) can only use local pid.
  This module is used to add, remove, and send events to the listener.
  """

  defstruct [:listeners]

  def new() do
    %__MODULE__{listeners: %{}}
  end

  @type t() :: %__MODULE__{listeners: %{pid() => %{event_types: [atom()], monitor_ref: reference(), tag: any()}}}

  @doc """
  Add a listener to the event listener.
  If the listener is already added, the event types will be updated.
  If the listener is not added, a monitor will be created and the listener will be added.
  The calling process handles the :DOWN message and calls remove
  """
  def add(%__MODULE__{listeners: listeners}, listener, event_types, tag \\ nil) do
    prev = Map.get(listeners, listener, nil)

    listeners =
      if prev do
        Map.put(
          listeners,
          listener,
          Map.put(prev, :event_types, event_types) |> Map.put(:tag, tag)
        )
      else
        monitor_ref = Process.monitor(listener)

        Map.put(listeners, listener, %{
          event_types: event_types,
          monitor_ref: monitor_ref,
          tag: tag
        })
      end

    %__MODULE__{listeners: listeners}
  end

  @doc """
  Remove a listener from the event listener.
  If the listener is not added, do nothing.
  If the listener is added, the monitor will be removed and the listener will be removed.
  The calling process handles the :DOWN message and calls remove
  """
  def remove(%__MODULE__{listeners: listeners}, listener) do
    case Map.pop(listeners, listener) do
      {nil, listeners} ->
        %__MODULE__{listeners: listeners}

      {%{monitor_ref: ref}, listeners} ->
        Process.demonitor(ref, [:flush])
        %__MODULE__{listeners: listeners}
    end
  end

  def send(%__MODULE__{listeners: listeners}, event_name, message) do
    for {listener, %{event_types: event_types, tag: tag}} <- listeners,
        event_name in event_types,
        do:
          if(tag == nil,
            do: send(listener, message),
            else:
              send(
                listener,
                if(is_tuple(message), do: Tuple.append(message, tag), else: {message, tag})
              )
          )
  end
end

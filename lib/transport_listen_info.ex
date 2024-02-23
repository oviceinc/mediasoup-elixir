defmodule Mediasoup.TransportListenInfo do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#TransportListenInfo
  """

  @typedoc "https://mediasoup.org/documentation/v3/mediasoup/api/#TransportListenIp"
  @type listen_ip :: %{:ip => String.t(), optional(:announcedIp) => String.t() | nil}

  @typedoc "https://mediasoup.org/documentation/v3/mediasoup/api/#TransportListenInfo"
  @type t :: %{
          :ip => String.t(),
          :protocol => :tcp | :udp,
          optional(:announcedAddress) => String.t() | nil,
          optional(:port) => integer(),
          optional(:sendBufferSize) => integer(),
          optional(:recvBufferSize) => integer()
        }

  @enforce_keys [:ip, :protocol]

  defstruct [:ip, :protocol, :announcedAddress, :port, :sendBufferSize, :recvBufferSize]

  def normalize_listen_ip(ip) when is_binary(ip) do
    %{:ip => ip}
  end

  def normalize_listen_ip(%{ip: _, announcedIp: announcedIp} = ip) do
    ip |> Map.delete(:announcedIp) |> Map.put(:announcedAddress, announcedIp)
  end

  def normalize_listen_ip(%{ip: _} = info) do
    info
  end

  def normalize(%{announcedIp: announcedIp} = listen_infos) do
    listen_infos |> Map.delete(:announcedIp) |> Map.put(:announcedAddress, announcedIp)
  end

  def normalize(info) do
    info
  end

  @spec create(binary() | %{:ip => any(), optional(any()) => any()}, any()) :: struct()
  def create(ip, protocol) do
    listen_ip = normalize_listen_ip(ip)
    struct(__MODULE__, Map.merge(listen_ip, %{:protocol => protocol}))
  end

  def create(ip, protocol, port) do
    listen_ip = normalize_listen_ip(ip)

    struct(
      __MODULE__,
      Map.merge(listen_ip, %{
        :protocol => protocol,
        :port => port
      })
    )
  end
end

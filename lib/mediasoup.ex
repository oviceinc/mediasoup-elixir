defmodule Mediasoup do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/
  """

  @version Mix.Project.config()[:version]
  @doc """
  return version of mediasoup_elixir
  """
  @spec version() :: String.t()
  def version(), do: @version

  @typedoc "https://mediasoup.org/documentation/v3/mediasoup/sctp-parameters/#NumSctpStreams"
  @type num_sctp_streams :: %{OS: integer(), MIS: integer()}
  @typedoc "https://mediasoup.org/documentation/v3/mediasoup/api/#TransportListenIp"
  @type transport_listen_ip :: %{:ip => String.t(), optional(:announcedIp) => String.t() | nil}

  @typedoc "https://mediasoup.org/documentation/v3/mediasoup/api/#TransportListenInfo"
  @type transport_listen_info :: %{
          :ip => String.t(),
          :protocol => :tcp | :udp,
          optional(:announcedIp) => String.t() | nil,
          optional(:port) => integer(),
          optional(:sendBufferSize) => integer(),
          optional(:recvBufferSize) => integer()
        }
end

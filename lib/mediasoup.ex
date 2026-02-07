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
  @type transport_listen_ip :: Mediasoup.TransportListenInfo.listen_ip()

  @typedoc "https://mediasoup.org/documentation/v3/mediasoup/api/#TransportListenInfo"
  @type transport_listen_info :: Mediasoup.TransportListenInfo.t()

  @doc """
  Since the format of env_logger is different from that of elixir, it is recommended to use Mediasoup.LoggerProxy instead.
  Initialize the logger with env logger. Same as the env_logger::init() call.
  For more information on the env logger, please refer to the Rust crate documentation.
  https://docs.rs/env_logger/latest/env_logger/
  """
  def init_env_logger(), do: Mediasoup.Nif.init_env_logger()

  @doc """
  Returns the RTP capabilities supported by the mediasoup library.

  See: https://mediasoup.org/documentation/v3/mediasoup/api/#mediasoup-getSupportedRtpCapabilities

  Note: These are NOT the RTP capabilities needed by mediasoup-client's `device.load()`.
  For that you must use `Router.rtp_capabilities/1` instead.

  ## Examples

      iex> caps = Mediasoup.get_supported_rtp_capabilities()
      iex> assert is_map(caps)
      iex> assert Map.has_key?(caps, "codecs")
  """
  @spec get_supported_rtp_capabilities() :: Mediasoup.Router.rtpCapabilities()
  def get_supported_rtp_capabilities(), do: Mediasoup.Nif.get_supported_rtp_capabilities()
end

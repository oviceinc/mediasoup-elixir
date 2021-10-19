defmodule Mediasoup.WebRtcTransport do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#WebRtcTransport
  """

  alias Mediasoup.{WebRtcTransport, Nif, Consumer, Producer}
  use Mediasoup.ProcessWrap.WithChildren
  @enforce_keys [:id]
  defstruct [:id, :reference, :pid]
  @type t :: %WebRtcTransport{id: String.t(), reference: reference | nil, pid: pid | nil}

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#WebRtcTransportOptions
    """

    @enforce_keys [:listen_ips]
    defstruct [
      :listen_ips,
      enable_udp: nil,
      enable_tcp: nil,
      prefer_udp: nil,
      prefer_tcp: nil,
      initial_available_outgoing_bitrate: nil,
      enable_sctp: nil,
      num_sctp_streams: nil,
      max_sctp_message_size: nil,
      sctp_send_buffer_size: nil
    ]

    @type t :: %Options{
            listen_ips: [Mediasoup.transport_listen_ip()],
            enable_udp: boolean | nil,
            enable_tcp: boolean | nil,
            prefer_udp: boolean | nil,
            prefer_tcp: boolean | nil,
            initial_available_outgoing_bitrate: integer() | nil,
            enable_sctp: boolean | nil,
            num_sctp_streams: Mediasoup.num_sctp_streams() | nil,
            max_sctp_message_size: integer() | nil,
            sctp_send_buffer_size: integer() | nil
          }

    def from_map(%{} = map) do
      map = for {key, val} <- map, into: %{}, do: {to_string(key), val}

      %Options{
        listen_ips: map["listenIps"],
        enable_udp: map["enableUdp"],
        enable_tcp: map["enableTcp"],
        prefer_udp: map["preferUdp"],
        prefer_tcp: map["preferTcp"],
        initial_available_outgoing_bitrate: map["initialAvailableOutgoingBitrate"],
        enable_sctp: map["enableSctp"],
        num_sctp_streams: map["numSctpStreams"],
        max_sctp_message_size: map["maxSctpMessageSize"],
        sctp_send_buffer_size: map["sctpSendBufferSize"]
      }
    end
  end

  @type create_option :: map | Options.t()

  @type connect_option :: map

  @type ice_parameter :: map()

  def id(%WebRtcTransport{id: id}) do
    id
  end

  @spec close(t) :: {:ok} | {:error}
  def close(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.stop(pid)
  end

  def close(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_close(reference)
  end

  @spec closed?(t) :: boolean
  def closed?(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    !Process.alive?(pid) || GenServer.call(pid, {:closed?, []})
  end

  def closed?(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_closed(reference)
  end

  @spec consume(t, Consumer.Options.t() | map()) ::
          {:ok, Consumer.t()} | {:error, String.t() | :terminated}
  def consume(%WebRtcTransport{pid: pid}, %Consumer.Options{} = option) when is_pid(pid) do
    GenServer.call(pid, {:start_child, Consumer, :consume, [option]})
  end

  def consume(%WebRtcTransport{reference: reference}, %Consumer.Options{} = option) do
    Nif.webrtc_transport_consume(reference, option)
  end

  def consume(transport, option) do
    consume(transport, Consumer.Options.from_map(option))
  end

  @spec produce(t, Producer.Options.t() | map()) ::
          {:ok, Producer.t()} | {:error, String.t() | :terminated}
  def produce(%WebRtcTransport{pid: pid}, %Producer.Options{} = option) when is_pid(pid) do
    GenServer.call(pid, {:start_child, Producer, :produce, [option]})
  end

  def produce(%WebRtcTransport{reference: reference}, %Producer.Options{} = option) do
    Nif.webrtc_transport_produce(reference, option)
  end

  def produce(transport, %{} = option) do
    produce(transport, Producer.Options.from_map(option))
  end

  @spec connect(t, connect_option()) :: {:ok} | {:error, String.t() | :terminated}

  def connect(%WebRtcTransport{pid: pid}, option) when is_pid(pid) do
    GenServer.call(pid, {:connect, [option]})
  end

  def connect(%WebRtcTransport{reference: reference}, option) do
    Nif.webrtc_transport_connect(reference, option)
  end

  @spec ice_parameters(t) :: ice_parameter() | {:error, :terminated}
  def ice_parameters(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:ice_parameters, []})
  end

  def ice_parameters(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_ice_parameters(reference)
  end

  @spec sctp_parameters(t) :: map() | {:error, :terminated}
  def sctp_parameters(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:sctp_parameters, []})
  end

  def sctp_parameters(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_sctp_parameters(reference)
  end

  @spec ice_candidates(t) :: list(any)
  def ice_candidates(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:ice_candidates, []})
  end

  def ice_candidates(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_ice_candidates(reference)
  end

  @spec ice_role(t) :: String.t() | {:error, :terminated}

  def ice_role(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:ice_role, []})
  end

  def ice_role(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_ice_role(reference)
  end

  @spec set_max_incoming_bitrate(t, integer) :: {:ok} | {:error, :terminated}
  def set_max_incoming_bitrate(%WebRtcTransport{pid: pid}, bitrate) when is_pid(pid) do
    GenServer.call(pid, {:set_max_incoming_bitrate, [bitrate]})
  end

  def set_max_incoming_bitrate(%WebRtcTransport{reference: reference}, bitrate) do
    Nif.webrtc_transport_set_max_incoming_bitrate(reference, bitrate)
  end

  @spec set_max_outgoing_bitrate(t, integer) :: {:ok} | {:error, :terminated}
  def set_max_outgoing_bitrate(%WebRtcTransport{pid: pid}, bitrate) when is_pid(pid) do
    GenServer.call(pid, {:set_max_outgoing_bitrate, [bitrate]})
  end

  def set_max_outgoing_bitrate(%WebRtcTransport{reference: reference}, bitrate) do
    Nif.webrtc_transport_set_max_outgoing_bitrate(reference, bitrate)
  end

  @spec ice_state(t) :: String.t() | {:error, :terminated}
  def ice_state(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:ice_state, []})
  end

  def ice_state(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_ice_state(reference)
  end

  @spec restart_ice(t) :: {:ok, ice_parameter} | {:error, :terminated}

  def restart_ice(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:restart_ice, []})
  end

  def restart_ice(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_restart_ice(reference)
  end

  @spec ice_selected_tuple(t) :: String.t() | nil | {:error, :terminated}
  def ice_selected_tuple(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:ice_selected_tuple, []})
  end

  def ice_selected_tuple(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_ice_selected_tuple(reference)
  end

  @spec dtls_parameters(t) :: map | {:error, :terminated}
  def dtls_parameters(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:dtls_parameters, []})
  end

  def dtls_parameters(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_dtls_parameters(reference)
  end

  @spec dtls_state(t) :: String.t() | {:error, :terminated}
  def dtls_state(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:dtls_state, []})
  end

  def dtls_state(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_dtls_state(reference)
  end

  @spec sctp_state(t) :: String.t() | {:error, :terminated}
  def sctp_state(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:sctp_state, []})
  end

  def sctp_state(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_sctp_state(reference)
  end

  @type transport_stat :: map
  @spec get_stats(t) :: list(transport_stat) | {:error, :terminated}
  def get_stats(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:get_stats, []})
  end

  def get_stats(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_get_stats(reference)
  end

  @spec dump(t) :: any | {:error, :terminated}
  def dump(%WebRtcTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:dump, []})
  end

  def dump(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_dump(reference)
  end

  @type event_type ::
          :on_close
          | :on_sctp_state_change
          | :on_ice_state_change
          | :on_dtls_state_change
          | :on_ice_selected_tuple_change

  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  def event(
        transport,
        listener,
        event_types \\ [
          :on_close,
          :on_sctp_state_change,
          :on_ice_state_change,
          :on_dtls_state_change,
          :on_ice_selected_tuple_change
        ]
      )

  def event(%WebRtcTransport{pid: pid}, listener, event_types) when is_pid(pid) do
    GenServer.call(pid, {:event, [listener, event_types]})
  end

  def event(%WebRtcTransport{reference: reference}, pid, event_types) do
    Nif.webrtc_transport_event(reference, pid, event_types)
  end
end

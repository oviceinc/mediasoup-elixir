defmodule Mediasoup.PlainTransport do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#PlainTransport
  """

  alias Mediasoup.{PlainTransport, Consumer, NifWrap, Nif}
  require NifWrap
  use GenServer, restart: :temporary

  @enforce_keys [:id]
  defstruct [:id, :pid]
  @type t :: %PlainTransport{id: String.t(), pid: pid}

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#PlainTransportOptions
    """

    @enforce_keys [:listen_ip]
    defstruct [
      :listen_ip,
      port: nil,
      rtcp_mux: nil,
      comedia: nil,
      enable_sctp: nil,
      num_sctp_streams: nil,
      max_sctp_message_size: nil,
      sctp_send_buffer_size: nil,
      enable_srtp: nil
    ]

    @type t :: %Options{
            listen_ip: Mediasoup.transport_listen_ip(),
            port: integer() | nil,
            rtcp_mux: boolean | nil,
            comedia: boolean | nil,
            enable_sctp: boolean | nil,
            num_sctp_streams: Mediasoup.num_sctp_streams() | nil,
            max_sctp_message_size: integer() | nil,
            sctp_send_buffer_size: integer() | nil,
            enable_srtp: boolean | nil
          }

    def from_map(%{} = map) do
      map = for {key, val} <- map, into: %{}, do: {to_string(key), val}

      %Options{
        listen_ip: map["listenIp"],
        port: map["port"],
        rtcp_mux: map["rtcpMux"],
        comedia: map["comedia"],
        enable_sctp: map["enableSctp"],
        num_sctp_streams: map["numSctpStreams"],
        max_sctp_message_size: map["maxSctpMessageSize"],
        sctp_send_buffer_size: map["sctpSendBufferSize"],
        enable_srtp: map["enableSrtp"]
      }
    end
  end

  @type transport_stat :: map()
  @type connect_option :: map()
  @type create_option :: map | Options.t()

  # Mediasoup Plain Transport Properties
  # https://mediasoup.org/documentation/v3/mediasoup/api/#PlainTransport-properties

  @spec id(t) :: String.t()
  @doc """
  PlainTransport identifier.
  """
  def id(%PlainTransport{id: id}) do
    id
  end

  @spec tuple(t) :: map() | {:error, :terminated}
  @doc """
  The transport tuple. If RTCP-mux is enabled (rtcpMux is set), this tuple refers to both RTP and RTCP.
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-tuple
  """
  def tuple(%PlainTransport{pid: pid}) do
    GenServer.call(pid, {:tuple, []})
  end

  @spec sctp_parameters(t) :: map() | {:error, :terminated}
  @doc """
  Local SCTP parameters. Or undefined if SCTP is not enabled.
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-sctpParameters
  """
  def sctp_parameters(%PlainTransport{pid: pid}) do
    GenServer.call(pid, {:sctp_parameters, []})
  end

  @spec sctp_state(t) :: String.t() | {:error, :terminated}
  @doc """
  Current SCTP state. Or undefined if SCTP is not enabled.
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-sctpState
  """
  def sctp_state(%PlainTransport{pid: pid}) do
    GenServer.call(pid, {:sctp_state, []})
  end

  @spec srtp_parameters(t) :: map() | {:error, :terminated}
  @doc """
  Local SRTP parameters representing the crypto suite and key material used to encrypt sending RTP and SRTP. Note that, if comedia mode is set, these local SRTP parameters may change after calling connect() with the remote SRTP parameters (to override the local SRTP crypto suite with the one given in connect().
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-srtpParameters
  """
  def srtp_parameters(%PlainTransport{pid: pid}) do
    GenServer.call(pid, {:srtp_parameters, []})
  end

  # Mediasoup Plain Transport Methods
  # https://mediasoup.org/documentation/v3/mediasoup/api/#PlainTransport-methods

  @spec get_stats(t) :: list(transport_stat) | {:error, :terminated}
  @doc """
  Returns current RTC statistics of the WebRTC transport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-getStats
  """
  def get_stats(%PlainTransport{pid: pid}) do
    GenServer.call(pid, {:get_stats, []})
  end

  @spec connect(t, connect_option()) :: {:ok} | {:error, String.t() | :terminated}
  @doc """
  Provides the plain transport with the endpoint parameters.
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-connect
  """
  def connect(%PlainTransport{pid: pid}, option) do
    GenServer.call(pid, {:connect, [option]})
  end

  @spec close(t) :: :ok

  @doc """
    Closes the PlainTransport.
  """
  def close(%PlainTransport{pid: pid}) do
    GenServer.stop(pid)
  end

  @spec closed?(t) :: boolean
  @doc """
  Tells whether the given PlainTransport is closed on the local node.
  """
  def closed?(%PlainTransport{pid: pid}) do
    !Process.alive?(pid) || GenServer.call(pid, {:closed?, []})
  end

  NifWrap.def_handle_call_nif(%{
    # properties
    id: &Nif.plain_transport_id/1,
    tuple: &Nif.plain_transport_tuple/1,
    sctp_parameters: &Nif.plain_transport_sctp_parameters/1,
    sctp_state: &Nif.plain_transport_sctp_state/1,
    srtp_parameters: &Nif.plain_transport_srtp_parameters/1,
    # methods
    connect: &Nif.plain_transport_connect/2,
    dump: &Nif.plain_transport_dump/1,
    get_stats: &Nif.plain_transport_get_stats/1,
    consume: &Nif.plain_transport_consume/2,
    close: &Nif.plain_transport_close/1,
    # events
    event: &Nif.plain_transport_event/3
  })

  # Mediasoup Plain Transport Events
  # https://mediasoup.org/documentation/v3/mediasoup/api/#PlainTransport-events

  @type event_type ::
          :on_close
          | :on_tuple
          | :on_sctp_state_change

  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  @doc """
  Starts observing event.
  """
  def event(
        transport,
        listener,
        event_types \\ [
          :on_close,
          :on_tuple,
          :on_sctp_state_change
        ]
      )

  def event(%PlainTransport{pid: pid}, listener, event_types) do
    GenServer.call(pid, {:event, [listener, event_types]})
  end

  # GenServer callbacks

  def start_link(opt) do
    reference = Keyword.fetch!(opt, :reference)
    GenServer.start_link(__MODULE__, %{reference: reference}, opt)
  end

  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)

    {:ok, Map.put(state, :supervisor, supervisor)}
  end

  @spec struct_from_pid(pid()) :: PlainTransport.t()
  def struct_from_pid(pid) do
    GenServer.call(pid, {:struct_from_pid, []})
  end

  def handle_call(
        {:struct_from_pid, _arg},
        _from,
        %{reference: reference} = state
      ) do
    {:reply,
     %PlainTransport{
       pid: self(),
       id: Nif.plain_transport_id(reference)
     }, state}
  end

  @spec consume(t, Consumer.Options.t() | map()) ::
          {:ok, Consumer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to send audio or video RTP (or SRTP depending on the transport class). This is the way to extract media from mediasoup.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-consume
  """
  def consume(%PlainTransport{pid: pid}, %Consumer.Options{} = option) do
    GenServer.call(pid, {:consume, [option]})
  end

  def consume(transport, option) do
    consume(transport, Consumer.Options.from_map(option))
  end

  def terminate(reason, %{reference: reference, supervisor: supervisor} = _state) do
    DynamicSupervisor.stop(supervisor, reason)
    Nif.plain_transport_close(reference)
    :ok
  end
end

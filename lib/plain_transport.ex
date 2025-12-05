defmodule Mediasoup.PlainTransport do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#PlainTransport
  """

  alias Mediasoup.{
    TransportListenInfo,
    PlainTransport,
    Consumer,
    Producer,
    NifWrap,
    Nif,
    EventListener
  }

  require NifWrap
  use GenServer, restart: :temporary, shutdown: 1000

  @enforce_keys [:id]
  defstruct [:id, :pid]
  @type t :: %PlainTransport{id: String.t(), pid: pid}

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#PlainTransportOptions
    """

    @enforce_keys []
    defstruct listen_ip: nil,
              listen_info: nil,
              rtcp_listen_info: nil,
              port: nil,
              rtcp_mux: nil,
              comedia: nil,
              enable_sctp: nil,
              num_sctp_streams: nil,
              max_sctp_message_size: nil,
              sctp_send_buffer_size: nil,
              enable_srtp: nil

    @type t :: %Options{
            listen_info: TransportListenInfo.t() | nil,
            rtcp_listen_info: TransportListenInfo.t() | nil,
            # deprecated use listen_info instead
            listen_ip: Mediasoup.transport_listen_ip() | nil,
            # deprecated use listen_info instead
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
        listen_info: map["listenInfo"],
        rtcp_listen_info: map["rtcpListenInfo"],
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

    def normalize(%Options{listen_ip: listen_ip, port: port} = option)
        when not is_nil(listen_ip) do
      normalize(%Options{
        option
        | listen_ip: nil,
          port: nil,
          listen_info:
            Map.get(option, :listen_info) ||
              TransportListenInfo.create(listen_ip, "udp", port),
          rtcp_listen_info:
            Map.get(option, :rtcp_listen_info) ||
              TransportListenInfo.create(listen_ip, "udp", nil)
      })
    end

    def normalize(%Options{} = option), do: option
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

  @spec tuple(t) :: TransportTuple.t() | {:error, :terminated}
  @doc """
  The transport tuple. If RTCP-mux is enabled (rtcpMux is set), this tuple refers to both RTP and RTCP.
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-tuple
  """
  def tuple(%PlainTransport{pid: pid}) do
    case NifWrap.call(pid, {:tuple, []}) do
      {:error, reason} ->
        {:error, reason}

      tuple ->
        %TransportTuple{
          local_port: tuple["localPort"],
          protocol: TransportTuple.protocol_to_atom(tuple["protocol"]),
          local_address: tuple["localAddress"],
          remote_ip: tuple["remoteIp"],
          remote_port: tuple["remotePort"]
        }
    end
  end

  @spec sctp_parameters(t) :: map() | {:error, :terminated}
  @doc """
  Local SCTP parameters. Or undefined if SCTP is not enabled.
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-sctpParameters
  """
  def sctp_parameters(%PlainTransport{pid: pid}) do
    NifWrap.call(pid, {:sctp_parameters, []})
  end

  @spec sctp_state(t) :: String.t() | {:error, :terminated}
  @doc """
  Current SCTP state. Or undefined if SCTP is not enabled.
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-sctpState
  """
  def sctp_state(%PlainTransport{pid: pid}) do
    NifWrap.call(pid, {:sctp_state, []})
  end

  @spec srtp_parameters(t) :: map() | {:error, :terminated}
  @doc """
  Local SRTP parameters representing the crypto suite and key material used to encrypt sending RTP and SRTP. Note that, if comedia mode is set, these local SRTP parameters may change after calling connect() with the remote SRTP parameters (to override the local SRTP crypto suite with the one given in connect().
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-srtpParameters
  """
  def srtp_parameters(%PlainTransport{pid: pid}) do
    NifWrap.call(pid, {:srtp_parameters, []})
  end

  # Mediasoup Plain Transport Methods
  # https://mediasoup.org/documentation/v3/mediasoup/api/#PlainTransport-methods

  @spec get_stats(t) :: list(transport_stat) | {:error, :terminated}
  @doc """
  Returns current RTC statistics of the WebRTC transport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-getStats
  """
  def get_stats(%PlainTransport{pid: pid}) do
    NifWrap.call(pid, {:get_stats, []})
  end

  @spec connect(t, connect_option()) :: {:ok} | {:error, String.t() | :terminated}
  @doc """
  Provides the plain transport with the endpoint parameters.
  https://mediasoup.org/documentation/v3/mediasoup/api/#plainTransport-connect
  """
  def connect(%PlainTransport{pid: pid}, option) do
    NifWrap.call(pid, {:connect, [option]})
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
    !Process.alive?(pid) ||
      case NifWrap.call(pid, {:closed?, []}) do
        {:error, :terminated} -> true
        result -> result
      end
  end

  @spec produce(t, Producer.Options.t() | map()) ::
          {:ok, Producer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to receive audio or video RTP (or SRTP depending on the transport class). This is the way to inject media into mediasoup.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-produce
  """
  def produce(%PlainTransport{pid: pid}, %Producer.Options{} = option) do
    NifWrap.call(pid, {:produce, [option]})
  end

  def produce(%PlainTransport{} = transport, %{} = option) do
    produce(transport, Producer.Options.from_map(option))
  end

  @spec consume(t, Consumer.Options.t() | map()) ::
          {:ok, Consumer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to send audio or video RTP (or SRTP depending on the transport class). This is the way to extract media from mediasoup.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-consume
  """
  def consume(%PlainTransport{pid: pid}, %Consumer.Options{} = option) do
    NifWrap.call(pid, {:consume, [option]})
  end

  def consume(%PlainTransport{} = transport, option) do
    consume(transport, Consumer.Options.from_map(option))
  end

  # GenServer callbacks

  def start_link(opt) do
    reference = Keyword.fetch!(opt, :reference)
    GenServer.start_link(__MODULE__, %{reference: reference}, opt)
  end

  @impl true
  def init(%{reference: reference} = state) do
    Nif.plain_transport_event(reference, self(), [
      :on_close,
      :on_tuple,
      :on_sctp_state_change
    ])

    {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)
    {:ok, Map.merge(state, %{supervisor: supervisor, listeners: EventListener.new()})}
  end

  @spec struct_from_pid(pid()) :: PlainTransport.t()
  def struct_from_pid(pid) do
    GenServer.call(pid, {:struct_from_pid, []})
  end

  def struct_from_pid_and_ref(pid, reference) do
    %PlainTransport{
      pid: pid,
      id: Nif.plain_transport_id(reference)
    }
  end

  @impl true
  def handle_call(
        {:event, listener, event_types},
        _from,
        %{listeners: listeners} = state
      ) do
    listeners = EventListener.add(listeners, listener, event_types)
    {:reply, {:ok}, %{state | listeners: listeners}}
  end

  @impl true
  def handle_call(
        {:struct_from_pid, _arg},
        _from,
        %{reference: reference} = state
      ) do
    {:reply, struct_from_pid_and_ref(self(), reference), state}
  end

  @impl true
  def handle_info(
        {:mediasoup_async_nif_result, {message_tag, from}, result},
        %{supervisor: supervisor} = state
      )
      when message_tag in [:produce, :consume] do
    module =
      case message_tag do
        :produce -> Producer
        :consume -> Consumer
      end

    GenServer.reply(from, NifWrap.handle_create_result(result, module, supervisor))
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:mediasoup_async_nif_result, {_, from}, result},
        state
      ) do
    GenServer.reply(from, result |> Nif.unwrap_ok())
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:DOWN, _monitor_ref, :process, listener, _reason},
        %{listeners: listeners} = state
      ) do
    listeners = EventListener.remove(listeners, listener)
    {:noreply, Map.put(state, :listeners, listeners)}
  end

  @impl true
  def handle_info({:nif_internal_event, :on_close}, state) do
    {:stop, :normal, state}
  end

  @payload_events [
    :on_sctp_state_change,
    :on_tuple
  ]

  @impl true
  def handle_info({:nif_internal_event, event, payload}, %{listeners: listeners} = state)
      when event in @payload_events do
    EventListener.send(listeners, event, {event, payload})
    {:noreply, state}
  end

  @impl true
  def terminate(
        reason,
        %{reference: reference, supervisor: supervisor, listeners: listeners} = _state
      ) do
    EventListener.send(listeners, :on_close, {:on_close})

    Mediasoup.Utility.supervisor_clean_stop(supervisor, reason)
    Nif.plain_transport_close(reference)
    :ok
  end

  NifWrap.def_handle_call_nif(%{
    # properties
    id: &Nif.plain_transport_id/1,
    tuple: &Nif.plain_transport_tuple/1,
    sctp_parameters: &Nif.plain_transport_sctp_parameters/1,
    sctp_state: &Nif.plain_transport_sctp_state/1,
    srtp_parameters: &Nif.plain_transport_srtp_parameters/1,
    # methods
    close: &Nif.plain_transport_close/1,
    closed?: &Nif.plain_transport_closed/1
  })

  NifWrap.def_handle_call_async_nif(%{
    connect: &Nif.plain_transport_connect_async/3,
    dump: &Nif.plain_transport_dump_async/2,
    get_stats: &Nif.plain_transport_get_stats_async/2,
    produce: &Nif.plain_transport_produce_async/3,
    consume: &Nif.plain_transport_consume_async/3
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
    NifWrap.call(pid, {:event, listener, event_types})
  end
end

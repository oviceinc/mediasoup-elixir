defmodule Mediasoup.WebRtcTransport do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#WebRtcTransport
  """

  alias Mediasoup.{WebRtcTransport, Consumer, Producer, NifWrap, Nif, DataConsumer, DataProducer}
  require NifWrap
  use GenServer, restart: :temporary

  @enforce_keys [:id]
  defstruct [:id, :pid]
  @type t :: %WebRtcTransport{id: String.t(), pid: pid}

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#WebRtcTransportOptions
    """

    @enforce_keys []
    defstruct listen_ips: nil,
              listen_infos: nil,
              webrtc_server: nil,
              listen: nil,
              port: nil,
              enable_udp: true,
              enable_tcp: nil,
              prefer_udp: false,
              prefer_tcp: false,
              initial_available_outgoing_bitrate: nil,
              enable_sctp: nil,
              num_sctp_streams: nil,
              max_sctp_message_size: nil,
              sctp_send_buffer_size: nil

    @type t :: %Options{
            # deprecated use listen instead
            listen_ips: [Mediasoup.transport_listen_ip()] | nil,
            # deprecated use listen instead
            listen_infos: [Mediasoup.transport_listen_info()] | nil,
            # deprecated use listen instead
            webrtc_server: Mediasoup.WebRtcServer.t() | nil,
            listen:
              [Mediasoup.transport_listen_info()]
              | Mediasoup.WebRtcServer.t()
              | nil,
            port: integer() | nil,
            enable_udp: boolean,
            enable_tcp: boolean | nil,
            prefer_udp: boolean,
            prefer_tcp: boolean,
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
        listen_infos: map["listenInfos"],
        webrtc_server: map["webrtcServer"],
        listen: map["listen"],
        enable_udp: Map.get(map, "enableUdp", true),
        enable_tcp: Map.get(map, "enableTcp", nil),
        prefer_udp: Map.get(map, "preferUdp", false),
        prefer_tcp: Map.get(map, "preferTcp", false),
        initial_available_outgoing_bitrate: map["initialAvailableOutgoingBitrate"],
        enable_sctp: map["enableSctp"],
        num_sctp_streams: map["numSctpStreams"],
        max_sctp_message_size: map["maxSctpMessageSize"],
        sctp_send_buffer_size: map["sctpSendBufferSize"]
      }
    end

    defp protocols(%{
           enable_udp: true,
           enable_tcp: true,
           prefer_udp: true
         }) do
      [:udp, :tcp]
    end

    defp protocols(%{
           enable_udp: true,
           enable_tcp: true,
           prefer_tcp: true
         }) do
      [:tcp, :udp]
    end

    defp protocols(%{
           enable_tcp: true
         }) do
      [:tcp]
    end

    defp protocols(%{
           enable_udp: true
         }) do
      [:udp]
    end

    defp protocols(_), do: []

    def normalize(
          %Options{
            listen_ips: listen_ips,
            port: port
          } = option
        )
        when not is_nil(listen_ips) do
      listen_ips =
        Enum.map(listen_ips, fn listen_ip ->
          if is_binary(listen_ip) do
            %{ip: listen_ip}
          else
            listen_ip
          end
        end)

      # Convert deprecated TransportListenIps to TransportListenInfos.
      protocols = protocols(option)

      listen_infos =
        Enum.flat_map(protocols, fn protocol ->
          Enum.map(listen_ips, fn listen_ip ->
            %{
              protocol: protocol,
              ip: listen_ip.ip,
              announcedIp: listen_ip[:announcedIp],
              port: port
            }
          end)
        end)

      normalize(%Options{
        option
        | listen_ips: nil,
          listen_infos: listen_infos
      })
    end

    def normalize(
          %Options{
            listen: %Mediasoup.WebRtcServer{} = listen
          } = option
        ) do
      normalize(%Options{
        option
        | listen: nil,
          webrtc_server: listen
      })
    end

    def normalize(
          %Options{
            listen: listen
          } = option
        )
        when not is_nil(listen) do
      normalize(%Options{
        option
        | listen: nil,
          listen_infos: listen
      })
    end

    def normalize(option) do
      option
    end
  end

  @type create_option :: map | Options.t()

  @type connect_option :: map

  @type ice_parameter :: map()

  @spec id(t) :: String.t()
  @doc """
  WebRtcTransport identifier.
  """
  def id(%WebRtcTransport{id: id}) do
    id
  end

  @spec close(t) :: :ok

  @doc """
    Closes the WebRtcTransport.
  """
  def close(%WebRtcTransport{pid: pid}) do
    GenServer.stop(pid)
  end

  @spec closed?(t) :: boolean
  @doc """
  Tells whether the given WebRtcTransport is closed on the local node.
  """
  def closed?(%WebRtcTransport{pid: pid}) do
    !Process.alive?(pid) || GenServer.call(pid, {:closed?, []})
  end

  @spec consume(t, Consumer.Options.t() | map()) ::
          {:ok, Consumer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to send audio or video RTP (or SRTP depending on the transport class). This is the way to extract media from mediasoup.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-consume
  """
  def consume(%WebRtcTransport{pid: pid}, %Consumer.Options{} = option) do
    GenServer.call(pid, {:consume, [option]})
  end

  def consume(transport, option) do
    consume(transport, Consumer.Options.from_map(option))
  end

  @spec consume_data(t, DataConsumer.Options.t() | map()) ::
          {:ok, DataConsumer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to send data messages to the endpoint via SCTP protocol or directly to the Node.js process if the transport is a DirectTransport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-consumedata
  """
  def consume_data(%WebRtcTransport{pid: pid}, %DataConsumer.Options{} = option) do
    GenServer.call(pid, {:consume_data, [option]})
  end

  def consume_data(transport, option) do
    consume_data(transport, DataConsumer.Options.from_map(option))
  end

  @spec produce(t, Producer.Options.t() | map()) ::
          {:ok, Producer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to receive audio or video RTP (or SRTP depending on the transport class). This is the way to inject media into mediasoup.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-produce
  """
  def produce(%WebRtcTransport{pid: pid}, %Producer.Options{} = option) do
    GenServer.call(pid, {:produce, [option]})
  end

  def produce(transport, %{} = option) do
    produce(transport, Producer.Options.from_map(option))
  end

  @spec produce_data(t, DataProducer.Options.t() | map()) ::
          {:ok, DataProducer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to receive data messages. Those messages can be delivered by an endpoint via SCTP protocol or can be directly sent from the Node.js application if the transport is a DirectTransport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-producedata
  """
  def produce_data(%WebRtcTransport{pid: pid}, %DataProducer.Options{} = option) do
    GenServer.call(pid, {:produce_data, [option]})
  end

  def produce_data(transport, %{} = option) do
    produce_data(transport, DataProducer.Options.from_map(option))
  end

  @spec connect(t, connect_option()) :: {:ok} | {:error, String.t() | :terminated}
  @doc """
  Provides the WebRTC transport with the endpoint parameters.
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-connect
  """
  def connect(%WebRtcTransport{pid: pid}, option) do
    GenServer.call(pid, {:connect, [option]})
  end

  @spec ice_parameters(t) :: ice_parameter() | {:error, :terminated}
  @doc """
  Local ICE parameters.
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-iceParameters
  """
  def ice_parameters(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:ice_parameters, []})
  end

  @spec sctp_parameters(t) :: map() | {:error, :terminated}
  @doc """
  Local SCTP parameters. Or undefined if SCTP is not enabled.
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-sctpParameters
  """
  def sctp_parameters(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:sctp_parameters, []})
  end

  @spec ice_candidates(t) :: list(any)

  @doc """
  Local ICE candidates.
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-iceCandidates
  """
  def ice_candidates(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:ice_candidates, []})
  end

  @spec ice_role(t) :: String.t() | {:error, :terminated}

  @doc """
  Local ICE role. Due to the mediasoup ICE Lite design, this is always “controlled”.
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-iceRole
  """
  def ice_role(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:ice_role, []})
  end

  @spec set_max_incoming_bitrate(t, integer) :: {:ok} | {:error, :terminated}
  def set_max_incoming_bitrate(%WebRtcTransport{pid: pid}, bitrate) do
    GenServer.call(pid, {:set_max_incoming_bitrate, [bitrate]})
  end

  @spec set_max_outgoing_bitrate(t, integer) :: {:ok} | {:error, :terminated}
  def set_max_outgoing_bitrate(%WebRtcTransport{pid: pid}, bitrate) do
    GenServer.call(pid, {:set_max_outgoing_bitrate, [bitrate]})
  end

  @spec ice_state(t) :: String.t() | {:error, :terminated}

  @doc """
  Current ICE state.
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-iceState
  """
  def ice_state(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:ice_state, []})
  end

  @spec restart_ice(t) :: {:ok, ice_parameter} | {:error, :terminated}

  @doc """
  Current ICE state.
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-iceState
  """
  def restart_ice(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:restart_ice, []})
  end

  @spec ice_selected_tuple(t) :: String.t() | nil | {:error, :terminated}
  @doc """
  The selected transport tuple if ICE is in “connected” or “completed” state. It is undefined if ICE is not established (no working candidate pair was found).
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-iceSelectedTuple
  """
  def ice_selected_tuple(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:ice_selected_tuple, []})
  end

  @spec dtls_parameters(t) :: map | {:error, :terminated}
  @doc """
  Local DTLS parameters.
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-dtlsParameters
  """
  def dtls_parameters(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:dtls_parameters, []})
  end

  @spec dtls_state(t) :: String.t() | {:error, :terminated}
  @doc """
  Current DTLS state.
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-dtlsState
  """
  def dtls_state(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:dtls_state, []})
  end

  @spec sctp_state(t) :: String.t() | {:error, :terminated}
  @doc """
  Current SCTP state. Or undefined if SCTP is not enabled.
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-sctpState
  """
  def sctp_state(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:sctp_state, []})
  end

  @type transport_stat :: map
  @spec get_stats(t) :: list(transport_stat) | {:error, :terminated}
  @doc """
  Returns current RTC statistics of the WebRTC transport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#webRtcTransport-getStats
  """
  def get_stats(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:get_stats, []})
  end

  @spec dump(t) :: any | {:error, :terminated}
  @doc """
  Dump internal stat for WebRtcTransport.
  """
  def dump(%WebRtcTransport{pid: pid}) do
    GenServer.call(pid, {:dump, []})
  end

  @type event_type ::
          :on_close
          | :on_sctp_state_change
          | :on_ice_state_change
          | :on_dtls_state_change
          | :on_ice_selected_tuple_change

  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  @doc """
  Starts observing event.
  """
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

  def event(%WebRtcTransport{pid: pid}, listener, event_types) do
    GenServer.call(pid, {:event, [listener, event_types]})
  end

  @spec struct_from_pid(pid()) :: WebRtcTransport.t()
  def struct_from_pid(pid) do
    GenServer.call(pid, {:struct_from_pid, []})
  end

  def struct_from_pid_and_ref(pid, reference) do
    %WebRtcTransport{
      pid: pid,
      id: Nif.webrtc_transport_id(reference)
    }
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

  def handle_call(
        {:event, [listener, event_types]},
        _from,
        %{reference: reference} = state
      ) do
    result =
      case NifWrap.EventProxy.wrap_if_remote_node(listener) do
        pid when is_pid(pid) -> Nif.webrtc_transport_event(reference, pid, event_types)
      end

    {:reply, result, state}
  end

  def handle_call(
        {:struct_from_pid, _arg},
        _from,
        %{reference: reference} = state
      ) do
    {:reply, struct_from_pid_and_ref(self(), reference), state}
  end

  NifWrap.def_handle_call_nif(%{
    close: &Nif.webrtc_transport_close/1,
    closed?: &Nif.webrtc_transport_closed/1,
    dump: &Nif.webrtc_transport_dump/1,
    get_stats: &Nif.webrtc_transport_get_stats/1,
    sctp_state: &Nif.webrtc_transport_sctp_state/1,
    connect: &Nif.webrtc_transport_connect/2,
    ice_parameters: &Nif.webrtc_transport_ice_parameters/1,
    ice_candidates: &Nif.webrtc_transport_ice_candidates/1,
    ice_role: &Nif.webrtc_transport_ice_role/1,
    ice_state: &Nif.webrtc_transport_ice_state/1,
    restart_ice: &Nif.webrtc_transport_restart_ice/1,
    ice_selected_tuple: &Nif.webrtc_transport_ice_selected_tuple/1,
    sctp_parameters: &Nif.webrtc_transport_sctp_parameters/1,
    set_max_incoming_bitrate: &Nif.webrtc_transport_set_max_incoming_bitrate/2,
    set_max_outgoing_bitrate: &Nif.webrtc_transport_set_max_outgoing_bitrate/2,
    dtls_parameters: &Nif.webrtc_transport_dtls_parameters/1,
    dtls_state: &Nif.webrtc_transport_dtls_state/1
  })

  def handle_call(
        {:produce, [option]},
        _from,
        %{reference: reference, supervisor: supervisor} = state
      ) do
    ret =
      Nif.webrtc_transport_produce(reference, option)
      |> NifWrap.handle_create_result(Producer, supervisor)

    {:reply, ret, state}
  end

  def handle_call(
        {:produce_data, [option]},
        _from,
        %{reference: reference, supervisor: supervisor} = state
      ) do
    ret =
      Nif.webrtc_transport_produce_data(reference, option)
      |> NifWrap.handle_create_result(DataProducer, supervisor)

    {:reply, ret, state}
  end

  def handle_call(
        {:consume, [option]},
        _from,
        %{reference: reference, supervisor: supervisor} = state
      ) do
    ret =
      Nif.webrtc_transport_consume(reference, option)
      |> NifWrap.handle_create_result(Consumer, supervisor)

    {:reply, ret, state}
  end

  def handle_call(
        {:consume_data, [option]},
        _from,
        %{reference: reference, supervisor: supervisor} = state
      ) do
    ret =
      Nif.webrtc_transport_consume_data(reference, option)
      |> NifWrap.handle_create_result(DataConsumer, supervisor)

    {:reply, ret, state}
  end

  def terminate(reason, %{reference: reference, supervisor: supervisor} = _state) do
    DynamicSupervisor.stop(supervisor, reason)
    Nif.webrtc_transport_close(reference)
    :ok
  end
end

defmodule Mediasoup.Router do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Router
  """
  alias Mediasoup.EventListener
  alias Mediasoup.{Router, WebRtcTransport, PipeTransport, PlainTransport, NifWrap, Nif}
  require NifWrap
  use GenServer, restart: :temporary, shutdown: 1000

  @enforce_keys [:id]
  defstruct [:id, :pid]
  @type t :: %Router{id: String.t(), pid: pid}

  @type media_codec :: %{
          :kind => :audio | :video | String.t(),
          :mimeType => String.t(),
          :clockRate => integer(),
          :channels => integer(),
          :parameters => map(),
          :rtcpFeedback => [map()],
          optional(:payloadType) => integer(),
          optional(:preferredPayloadType) => integer()
        }
  @type rtpCapabilities :: any

  @type create_option :: Mediasoup.Router.Options.t() | map

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#RouterOptions
    """

    @enforce_keys [:media_codecs]
    defstruct media_codecs: nil

    @type t :: %Options{
            media_codecs: [Mediasoup.Router.media_codec()]
          }

    @spec from_map(map) :: t()
    def from_map(%{} = map) do
      map = for {key, val} <- map, into: %{}, do: {to_string(key), val}

      %Options{
        media_codecs: map["mediaCodecs"]
      }
    end
  end

  defmodule PipeToRouterOptions do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#PipeToRouterOptions
    without producerId.
    producerId is the argument of the function
    """
    @type num_sctp_streams :: %{OS: integer(), MIS: integer()}

    @enforce_keys [:router]
    defstruct [
      :router,
      enable_sctp: nil,
      num_sctp_streams: nil,
      enable_rtx: nil,
      enable_srtp: nil,
      get_remote_node_ip: &Mediasoup.Utility.get_remote_node_ip/2,
      get_listen_ip: &Mediasoup.Utility.get_listen_ip/2
    ]

    @type t :: %PipeToRouterOptions{
            router: Mediasoup.Router.t(),
            enable_sctp: boolean() | nil,
            num_sctp_streams: num_sctp_streams() | nil,
            enable_rtx: boolean() | nil,
            enable_srtp: boolean() | nil,
            get_remote_node_ip:
              (node, node -> {:ok, String.t()} | {:error, message :: String.t() | atom()}),
            get_listen_ip:
              (node, node -> {:ok, String.t()} | {:error, message :: String.t() | atom()})
          }
  end

  defmodule PipeToRouterResult do
    defstruct pipe_consumer: nil,
              pipe_producer: nil,
              pipe_data_consumer: nil,
              pipe_data_producer: nil

    @type t :: %PipeToRouterResult{
            pipe_consumer: Mediasoup.Consumer.t() | nil,
            pipe_producer: Mediasoup.Producer.t() | nil,
            pipe_data_consumer: Mediasoup.DataConsumer.t() | nil,
            pipe_data_producer: Mediasoup.DataProducer.t() | nil
          }
  end

  @spec id(Mediasoup.Router.t()) :: String.t()
  @doc """
  Router identifier.
  """
  def id(%Router{id: id}) do
    id
  end

  @spec close(t) :: :ok
  @doc """
    Closes the router.
  """
  def close(%Router{pid: pid}) do
    GenServer.stop(pid)
  end

  @spec closed?(t) :: boolean
  @doc """
  Tells whether the given router is closed on the local node.
  """
  def closed?(%Router{pid: pid}) do
    !Process.alive?(pid) ||
      case NifWrap.call(pid, {:closed?, []}) do
        {:error, :terminated} -> true
        result -> result
      end
  end

  @spec create_webrtc_transport(t, WebRtcTransport.create_option()) ::
          {:ok, WebRtcTransport.t()} | {:error, String.t()}
  @doc """
  Creates a new webrtc transport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#router-createWebRtcTransport
  """
  def create_webrtc_transport(
        %Router{pid: pid},
        %WebRtcTransport.Options{} = option
      ) do
    option = WebRtcTransport.Options.normalize(option)
    NifWrap.call(pid, {:create_webrtc_transport, [option]})
  end

  def create_webrtc_transport(%Router{} = router, %{} = option) do
    create_webrtc_transport(router, WebRtcTransport.Options.from_map(option))
  end

  @spec create_plain_transport(t, PlainTransport.create_option()) ::
          {:ok, PlainTransport.t()} | {:error, String.t()}
  @doc """
  Creates a new webrtc transport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#router-createPlainTransport
  """
  def create_plain_transport(
        %Router{pid: pid},
        %Mediasoup.PlainTransport.Options{} = option
      ) do
    option = Mediasoup.PlainTransport.Options.normalize(option)
    NifWrap.call(pid, {:create_plain_transport, [option]})
  end

  def create_plain_transport(%Router{} = router, %{} = option) do
    create_plain_transport(router, Mediasoup.PlainTransport.Options.from_map(option))
  end

  @spec pipe_producer_to_router(t, producer_id :: String.t(), PipeToRouterOptions.t()) ::
          {:ok, PipeToRouterResult.t()} | {:error, String.t()}

  @doc """
  Pipes the given media producer into another router.
  https://mediasoup.org/documentation/v3/mediasoup/api/#router-pipeToRouter
  """
  def pipe_producer_to_router(
        %Router{} = router,
        producer_id,
        %PipeToRouterOptions{} = option
      ) do
    try do
      do_pipe_producer_to_router(router, producer_id, option)
    catch
      reason, msg -> {:error, {reason, msg}}
    end
  end

  defp do_pipe_producer_to_router(
         %Router{} = router,
         producer_id,
         %PipeToRouterOptions{} = option
       ) do
    alias Mediasoup.{Consumer, Producer, Transport}

    with {:ok, %{local: local_pipe_transport, remote: remote_pipe_transport}} <-
           get_or_create_pipe_transport_pair(router, option),
         {:ok, pipe_consumer} <-
           Transport.consume(local_pipe_transport, %Consumer.Options{
             producer_id: producer_id,
             rtp_capabilities: Router.rtp_capabilities(router)
           }),
         {:ok, pipe_producer} <-
           Transport.produce(remote_pipe_transport, %Producer.Options{
             id: producer_id,
             kind: Consumer.kind(pipe_consumer),
             rtp_parameters: Consumer.rtp_parameters(pipe_consumer),
             paused: Consumer.producer_paused?(pipe_consumer)
           }) do
      Consumer.link_pipe_producer(pipe_consumer, pipe_producer)

      {:ok, %{pipe_producer: pipe_producer, pipe_consumer: pipe_consumer}}
    end
  end

  @spec pipe_data_producer_to_router(t, data_producer_id :: String.t(), PipeToRouterOptions.t()) ::
          {:ok, PipeToRouterResult.t()} | {:error, String.t()}
  @doc """
  Pipes the given data producer into another router.
  https://mediasoup.org/documentation/v3/mediasoup/api/#router-pipeToRouter
  """
  def pipe_data_producer_to_router(
        %Router{} = router,
        data_producer_id,
        %PipeToRouterOptions{} = option
      ) do
    try do
      do_pipe_data_producer_to_router(router, data_producer_id, option)
    catch
      reason, msg -> {:error, {reason, msg}}
    end
  end

  defp do_pipe_data_producer_to_router(
         %Router{} = router,
         data_producer_id,
         %PipeToRouterOptions{} = option
       ) do
    alias Mediasoup.{DataConsumer, DataProducer, Transport}

    with {:ok, %{local: local_pipe_transport, remote: remote_pipe_transport}} <-
           get_or_create_pipe_transport_pair(router, option),
         {:ok, pipe_consumer} <-
           Transport.consume_data(local_pipe_transport, %DataConsumer.Options{
             data_producer_id: data_producer_id,
             ordered: true
           }),
         {:ok, pipe_producer} <-
           Transport.produce_data(remote_pipe_transport, %DataProducer.Options{
             sctp_stream_parameters: DataConsumer.sctp_stream_parameters(pipe_consumer)
           }) do
      DataConsumer.link_pipe_producer(pipe_consumer, pipe_producer)

      {:ok, %{pipe_data_producer: pipe_producer, pipe_data_consumer: pipe_consumer}}
    end
  end

  @spec create_pipe_transport(
          Router.t(),
          PipeTransport.Options.t()
        ) :: {:ok, PipeTransport.t()} | {:error, String.t()}
  @doc """
  Creates a new pipe transport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#router-createPipeTransport
  """
  def create_pipe_transport(%Router{pid: pid}, %PipeTransport.Options{} = option) do
    NifWrap.call(pid, {:create_pipe_transport, [PipeTransport.Options.normalize(option)]})
  end

  @spec can_consume?(t, String.t(), rtpCapabilities) :: boolean
  @doc """
  Whether the given RTP capabilities are valid to consume the given producer.
  https://mediasoup.org/documentation/v3/mediasoup/api/#router-canConsume
  """
  def can_consume?(%Router{pid: pid}, producer_id, rtp_capabilities) do
    NifWrap.call(pid, {:can_consume?, [producer_id, rtp_capabilities]})
  end

  @spec rtp_capabilities(t) :: Router.rtpCapabilities()
  @doc """
  An Object with the RTP capabilities of the router.
  https://mediasoup.org/documentation/v3/mediasoup/api/#router-rtpCapabilities
  """
  def rtp_capabilities(%Router{pid: pid}) do
    NifWrap.call(pid, {:rtp_capabilities, []})
  end

  @spec dump(t) :: map | {:error}
  @doc """
  Dump internal stat for Router.
  """
  def dump(%Router{pid: pid}) do
    NifWrap.call(pid, {:dump, []})
  end

  @type event_type ::
          :on_close
          | :on_dead

  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  @doc """
  Starts observing event.
  """
  def event(
        router,
        listener,
        event_types \\ [
          :on_close,
          :on_dead
        ]
      )

  def event(%Router{pid: pid}, listener, event_types) do
    NifWrap.call(pid, {:event, listener, event_types})
  end

  @spec struct_from_pid(pid()) :: Router.t()
  def struct_from_pid(pid) do
    GenServer.call(pid, {:struct_from_pid, []})
  end

  def struct_from_pid_and_ref(pid, reference) do
    %Router{
      pid: pid,
      id: Nif.router_id(reference)
    }
  end

  # GenServer callbacks

  def start_link(opt) do
    reference = Keyword.fetch!(opt, :reference)
    GenServer.start_link(__MODULE__, %{reference: reference}, opt)
  end

  @impl true
  def init(%{reference: reference} = state) do
    {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)

    {:ok} =
      Nif.router_event(reference, self(), [
        :on_close,
        :on_dead
      ])

    {:ok, Map.put(state, :supervisor, supervisor) |> Map.put(:listeners, EventListener.new())}
  end

  @impl true
  def handle_call(
        {:event, listener, event_types},
        _from,
        %{listeners: listeners} = state
      ) do
    listeners = EventListener.add(listeners, listener, event_types)

    {:reply, :ok, Map.put(state, :listeners, listeners)}
  end

  def handle_call(
        {:struct_from_pid, _arg},
        _from,
        %{reference: reference} = state
      ) do
    {:reply, struct_from_pid_and_ref(self(), reference), state}
  end

  NifWrap.def_handle_call_nif(%{
    closed?: &Nif.router_closed/1,
    can_consume?: &Nif.router_can_consume/3,
    rtp_capabilities: &Nif.router_rtp_capabilities/1
  })

  NifWrap.def_handle_call_async_nif(%{
    dump: &Nif.router_dump_async/2,
    create_pipe_transport: &Nif.router_create_pipe_transport_async/3,
    create_plain_transport: &Nif.router_create_plain_transport_async/3
  })

  @impl true
  def handle_call(
        {:create_webrtc_transport, [option]},
        from,
        %{reference: reference} = state
      ) do
    option =
      Map.update(option, :webrtc_server, nil, fn webrtc_server ->
        if webrtc_server != nil do
          Mediasoup.WebRtcServer.to_ref(option.webrtc_server)
        else
          nil
        end
      end)

    case Nif.router_create_webrtc_transport_async(
           reference,
           option,
           {:create_webrtc_transport, from}
         ) do
      :ok -> {:noreply, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call(
        {:get_pipe_transport_pair, id},
        _from,
        %{mapped_pipe_transports: mapped_pipe_transports} = state
      ) do
    case Map.fetch(mapped_pipe_transports, id) do
      {:ok, pair} -> {:reply, pair, state}
      _ -> {:reply, nil, state}
    end
  end

  def handle_call({:get_pipe_transport_pair, _id}, _from, state) do
    {:reply, nil, state}
  end

  def handle_call(
        {:put_pipe_transport_pair, id, pair},
        _from,
        %{mapped_pipe_transports: mapped_pipe_transports} = state
      ) do
    {:reply, :ok, %{state | mapped_pipe_transports: Map.put(mapped_pipe_transports, id, pair)}}
  end

  def handle_call({:put_pipe_transport_pair, id, pair}, _from, state) do
    {:reply, :ok, Map.put(state, :mapped_pipe_transports, %{id => pair})}
  end

  def handle_info(
        {:mediasoup_async_nif_result, {operation, from}, result},
        %{supervisor: supervisor} = state
      )
      when operation in [
             :create_pipe_transport,
             :create_plain_transport,
             :create_webrtc_transport
           ] do
    module =
      case operation do
        :create_pipe_transport -> PipeTransport
        :create_plain_transport -> PlainTransport
        :create_webrtc_transport -> WebRtcTransport
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

  def handle_info(
        {:nif_internal_event, :on_close},
        state
      ) do
    {:stop, :normal, state}
  end

  def handle_info(
        {:nif_internal_event, :on_dead, message},
        %{listeners: listeners} = state
      ) do
    EventListener.send(listeners, :on_dead, {:on_dead, message})
    {:stop, :shutdown, state}
  end

  @impl true
  def terminate(
        reason,
        %{reference: reference, supervisor: supervisor, listeners: listeners} = _state
      ) do
    EventListener.send(listeners, :on_close, {:on_close})
    Mediasoup.Utility.supervisor_clean_stop(supervisor, reason)

    Nif.router_close(reference)
    :ok
  end

  defp get_node(%Router{pid: pid}) do
    node(pid)
  end

  defp get_pipe_transport_pair(
         %Router{pid: pid},
         %PipeToRouterOptions{router: remote_router}
       ) do
    NifWrap.call(pid, {:get_pipe_transport_pair, Router.id(remote_router)})
  end

  defp put_pipe_transport_pair(
         %Router{pid: pid},
         %PipeToRouterOptions{router: remote_router},
         pair
       ) do
    NifWrap.call(pid, {:put_pipe_transport_pair, Router.id(remote_router), pair})
  end

  defp get_or_create_pipe_transport_pair(
         %Router{} = router,
         %PipeToRouterOptions{router: %Router{pid: _pid2}} = option
       ) do
    case get_pipe_transport_pair(router, option) do
      nil ->
        create_pipe_transport_pair(router, option)

      pair ->
        {:ok, pair}
    end
  end

  defp create_pipe_transport_pair(
         %Router{pid: _pid} = router,
         %PipeToRouterOptions{
           router: %Router{pid: _pid2} = remote_router,
           enable_sctp: enable_sctp,
           num_sctp_streams: num_sctp_streams,
           enable_rtx: enable_rtx,
           enable_srtp: enable_srtp,
           get_remote_node_ip: get_remote_node_ip,
           get_listen_ip: get_listen_ip
         } = option
       ) do
    local_node = get_node(router)
    remote_node = get_node(remote_router)

    with {:ok, remote_ip} <- get_remote_node_ip.(local_node, remote_node),
         {:ok, local_ip} <- get_remote_node_ip.(remote_node, local_node),
         {:ok, local_listen_ip} <- get_listen_ip.(local_node, remote_node),
         {:ok, remote_listen_ip} <- get_listen_ip.(remote_node, local_node),
         {:ok, local_pipe_transport} <-
           Router.create_pipe_transport(router, %PipeTransport.Options{
             listen_ip: %{ip: local_listen_ip},
             enable_sctp: enable_sctp,
             num_sctp_streams: num_sctp_streams,
             enable_rtx: enable_rtx,
             enable_srtp: enable_srtp
           }),
         {:ok, remote_pipe_transport} <-
           Router.create_pipe_transport(remote_router, %PipeTransport.Options{
             listen_ip: %{ip: remote_listen_ip},
             enable_sctp: enable_sctp,
             num_sctp_streams: num_sctp_streams,
             enable_rtx: enable_rtx,
             enable_srtp: enable_srtp
           }) do
      %{local_port: local_port} = PipeTransport.tuple(local_pipe_transport)
      %{local_port: remote_port} = PipeTransport.tuple(remote_pipe_transport)

      with {:ok} <-
             PipeTransport.connect(local_pipe_transport, %{ip: remote_ip, port: remote_port}),
           {:ok} <-
             PipeTransport.connect(remote_pipe_transport, %{ip: local_ip, port: local_port}) do
        pair = %{local: local_pipe_transport, remote: remote_pipe_transport}
        put_pipe_transport_pair(router, option, pair)
        {:ok, pair}
      end
    end
  end
end

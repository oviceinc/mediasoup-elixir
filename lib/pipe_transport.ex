defmodule Mediasoup.PipeTransport do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#PipeTransport
  """
  alias Mediasoup.{
    TransportListenInfo,
    PipeTransport,
    Consumer,
    DataConsumer,
    Producer,
    DataProducer,
    NifWrap,
    Nif,
    EventListener
  }

  require NifWrap
  use GenServer, restart: :temporary, shutdown: 1000

  @enforce_keys [:id]
  defstruct [:id, :pid]
  @type t :: %PipeTransport{id: String.t(), pid: pid}

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#PipeTransportOptions
    """

    @enforce_keys []
    defstruct listen_ip: nil,
              listen_info: nil,
              port: nil,
              enable_sctp: nil,
              num_sctp_streams: nil,
              max_sctp_message_size: nil,
              sctp_send_buffer_size: nil,
              enable_rtx: nil,
              enable_srtp: nil

    @type t :: %Options{
            listen_info: Mediasoup.transport_listen_info() | nil,
            # deprecated use listen_info instead
            listen_ip: Mediasoup.transport_listen_ip() | nil,
            # deprecated use listen_info instead
            port: integer() | nil,
            enable_sctp: boolean | nil,
            num_sctp_streams: Mediasoup.num_sctp_streams() | nil,
            max_sctp_message_size: integer() | nil,
            sctp_send_buffer_size: integer() | nil,
            enable_rtx: boolean | nil,
            enable_srtp: boolean | nil
          }
    def normalize(%Options{listen_ip: listen_ip, port: port} = option)
        when not is_nil(listen_ip) do
      listen_info = TransportListenInfo.create(listen_ip, "udp", port)

      normalize(%Options{
        option
        | listen_ip: nil,
          port: nil,
          listen_info: listen_info
      })
    end

    def normalize(%Options{} = option), do: option
  end

  @typedoc """
  https://mediasoup.org/documentation/v3/mediasoup/sctp-parameters/#SctpParameters
  """
  @type sctp_parameters_t :: map()

  @typedoc """
  https://mediasoup.org/documentation/v3/mediasoup/srtp-parameters/#SrtpParameters
  """
  @type srtp_parameters_t :: map()

  @type connect_option :: %{
          :ip => String.t(),
          :port => integer,
          optional(:srtpParameters) => srtp_parameters_t() | nil
        }

  @doc """
  PipeTransport identifier.
  """
  @spec id(t) :: String.t()
  def id(%PipeTransport{id: id}) do
    id
  end

  @spec close(t) :: :ok
  @doc """
  Closes the PipeTransport.
  """
  def close(%PipeTransport{pid: pid}) do
    GenServer.stop(pid)
  end

  @spec closed?(t) :: boolean
  @doc """
  Tells whether the given PipeTransport is closed on the local node.
  """
  def closed?(%PipeTransport{pid: pid}) do
    !Process.alive?(pid) ||
      case NifWrap.call(pid, {:closed?, []}) do
        {:error, :terminated} -> true
        result -> result
      end
  end

  @spec consume(t, Consumer.Options.t() | map()) ::
          {:ok, Consumer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to send audio or video RTP (or SRTP depending on the transport class). This is the way to extract media from mediasoup.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-consume
  """
  def consume(%PipeTransport{pid: pid}, %Consumer.Options{} = option) do
    NifWrap.call(pid, {:consume, [option]})
  end

  def consume(%PipeTransport{} = transport, option) do
    consume(transport, Consumer.Options.from_map(option))
  end

  @spec consume_data(t, DataConsumer.Options.t() | map()) ::
          {:ok, DataConsumer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to send data messages to the endpoint via SCTP protocol or directly to the Rust process if the transport is a DirectTransport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-consumedata
  """
  def consume_data(%PipeTransport{pid: pid}, %DataConsumer.Options{} = option) do
    NifWrap.call(pid, {:consume_data, [option]})
  end

  def consume_data(%PipeTransport{} = transport, option) do
    consume_data(transport, DataConsumer.Options.from_map(option))
  end

  @spec connect(t, option :: connect_option()) :: {:ok} | {:error, String.t() | :terminated}
  @doc """
  Provides the pipe RTP transport with the remote parameters.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-connect
  """
  def connect(%PipeTransport{pid: pid}, option) do
    NifWrap.call(pid, {:connect, [option]})
  end

  @spec produce(t, Producer.Options.t() | map()) ::
          {:ok, Producer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to receive audio or video RTP (or SRTP depending on the transport class). This is the way to inject media into mediasoup.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-produce
  """
  def produce(%PipeTransport{pid: pid}, %Producer.Options{} = option) do
    NifWrap.call(pid, {:produce, [option]})
  end

  def produce(%PipeTransport{} = transport, %{} = option) do
    produce(transport, Producer.Options.from_map(option))
  end

  @spec produce_data(t, DataProducer.Options.t() | map()) ::
          {:ok, DataProducer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to receive data messages. Those messages can be delivered by an endpoint via SCTP protocol or can be directly sent from the Node.js application if the transport is a DirectTransport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-producedata
  """
  def produce_data(%PipeTransport{pid: pid}, %DataProducer.Options{} = option) do
    NifWrap.call(pid, {:produce_data, [option]})
  end

  def produce_data(%PipeTransport{} = transport, %{} = option) do
    produce_data(transport, DataProducer.Options.from_map(option))
  end

  @type transport_stat :: map
  @spec get_stats(t) :: list(transport_stat) | {:error, :terminated}
  @doc """
  Returns current RTC statistics of the pipe transport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-getStats
  """
  def get_stats(%PipeTransport{pid: pid}) do
    NifWrap.call(pid, {:get_stats, []})
  end

  @typedoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#TransportTuple
  """
  @spec tuple(t) :: TransportTuple.t() | {:error, :terminated}
  @doc """
  The transport tuple. It refers to both RTP and RTCP since pipe transports use RTCP-mux by design.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-tuple
  """
  def tuple(%PipeTransport{pid: pid}) do
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

  @spec sctp_parameters(Mediasoup.PipeTransport.t()) ::
          sctp_parameters_t() | {:error, :terminated}
  @doc """
  Local SCTP parameters. Or undefined if SCTP is not enabled.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-sctpParameters
  """
  def sctp_parameters(%PipeTransport{pid: pid}) do
    NifWrap.call(pid, {:sctp_parameters, []})
  end

  @spec srtp_parameters(Mediasoup.PipeTransport.t()) ::
          srtp_parameters_t() | {:error, :terminated}
  @doc """
  Local SRTP parameters representing the crypto suite and key material used to encrypt sending RTP and SRTP.
  Those parameters must be given to the paired pipeTransport in the connect() method.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-srtpParameters
  """
  def srtp_parameters(%PipeTransport{pid: pid}) do
    NifWrap.call(pid, {:srtp_parameters, []})
  end

  @spec sctp_state(Mediasoup.PipeTransport.t()) :: String.t() | {:error, :terminated}
  @doc """
  Current SCTP state. Or undefined if SCTP is not enabled.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-sctpState
  """
  def sctp_state(%PipeTransport{pid: pid}) do
    NifWrap.call(pid, {:sctp_state, []})
  end

  @spec dump(t) :: any | {:error, :terminated}
  @doc """
  Dump internal stat for PipeTransport.
  """
  def dump(%PipeTransport{pid: pid}) do
    NifWrap.call(pid, {:dump, []})
  end

  @type event_type ::
          :on_close
          | :on_sctp_state_change
          | :on_tuple

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
          :on_tuple
        ]
      )

  def event(%PipeTransport{pid: pid}, listener, event_types) do
    NifWrap.call(pid, {:event, listener, event_types})
  end

  @spec struct_from_pid(pid()) :: PipeTransport.t()
  def struct_from_pid(pid) do
    GenServer.call(pid, {:struct_from_pid, []})
  end

  def struct_from_pid_and_ref(pid, reference) do
    %PipeTransport{
      pid: pid,
      id: Nif.pipe_transport_id(reference)
    }
  end

  # GenServer callbacks

  def start_link(opt) do
    reference = Keyword.fetch!(opt, :reference)
    GenServer.start_link(__MODULE__, %{reference: reference}, opt)
  end

  @impl true
  def init(state) do
    {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)
    {:ok, Map.merge(state, %{supervisor: supervisor, listeners: EventListener.new()})}
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

  NifWrap.def_handle_call_nif(%{
    close: &Nif.pipe_transport_close/1,
    closed?: &Nif.pipe_transport_closed/1,
    sctp_state: &Nif.pipe_transport_sctp_state/1,
    tuple: &Nif.pipe_transport_tuple/1,
    sctp_parameters: &Nif.pipe_transport_sctp_parameters/1,
    srtp_parameters: &Nif.pipe_transport_srtp_parameters/1
  })

  NifWrap.def_handle_call_async_nif(%{
    connect: &Nif.pipe_transport_connect_async/3,
    dump: &Nif.pipe_transport_dump_async/2,
    get_stats: &Nif.pipe_transport_get_stats_async/2,
    produce: &Nif.pipe_transport_produce_async/3,
    produce_data: &Nif.pipe_transport_produce_data_async/3,
    consume: &Nif.pipe_transport_consume_async/3,
    consume_data: &Nif.pipe_transport_consume_data_async/3
  })

  @impl true
  def handle_info(
        {:mediasoup_async_nif_result, {message_tag, from}, result},
        %{supervisor: supervisor} = state
      )
      when message_tag in [:produce, :consume, :produce_data, :consume_data] do
    module =
      case message_tag do
        :produce -> Producer
        :consume -> Consumer
        :produce_data -> DataProducer
        :consume_data -> DataConsumer
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
    {:noreply, %{state | listeners: listeners}}
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
    Nif.pipe_transport_close(reference)
    :ok
  end
end

defmodule Mediasoup.PipeTransport do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#PipeTransport
  """
  alias Mediasoup.{PipeTransport, Consumer, Producer, NifWrap, Nif}
  require NifWrap
  use GenServer, restart: :temporary

  @enforce_keys [:id]
  defstruct [:id, :pid]
  @type t :: %PipeTransport{id: String.t(), pid: pid}

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#PipeTransportOptions
    """

    @enforce_keys [:listen_ip]
    defstruct [
      :listen_ip,
      port: nil,
      enable_sctp: nil,
      num_sctp_streams: nil,
      max_sctp_message_size: nil,
      sctp_send_buffer_size: nil,
      enable_rtx: nil,
      enable_srtp: nil
    ]

    @type t :: %Options{
            listen_ip: Mediasoup.transport_listen_ip(),
            port: integer() | nil,
            enable_sctp: boolean | nil,
            num_sctp_streams: Mediasoup.num_sctp_streams() | nil,
            max_sctp_message_size: integer() | nil,
            sctp_send_buffer_size: integer() | nil,
            enable_rtx: boolean | nil,
            enable_srtp: boolean | nil
          }
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
    !Process.alive?(pid) || GenServer.call(pid, {:closed?, []})
  end

  @spec consume(t, Consumer.Options.t() | map()) ::
          {:ok, Consumer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to send audio or video RTP (or SRTP depending on the transport class). This is the way to extract media from mediasoup.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-consume
  """
  def consume(%PipeTransport{pid: pid}, %Consumer.Options{} = option) do
    GenServer.call(pid, {:consume, [option]})
  end

  def consume(transport, option) do
    consume(transport, Consumer.Options.from_map(option))
  end

  @spec connect(t, option :: connect_option()) :: {:ok} | {:error, String.t() | :terminated}
  @doc """
  Provides the pipe RTP transport with the remote parameters.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-connect
  """
  def connect(%PipeTransport{pid: pid}, option) do
    GenServer.call(pid, {:connect, [option]})
  end

  @spec produce(t, Producer.Options.t() | map()) ::
          {:ok, Producer.t()} | {:error, String.t() | :terminated}
  @doc """
  Instructs the router to receive audio or video RTP (or SRTP depending on the transport class). This is the way to inject media into mediasoup.
  https://mediasoup.org/documentation/v3/mediasoup/api/#transport-produce
  """
  def produce(%PipeTransport{pid: pid}, %Producer.Options{} = option) do
    GenServer.call(pid, {:produce, [option]})
  end

  def produce(transport, %{} = option) do
    produce(transport, Producer.Options.from_map(option))
  end

  @type transport_stat :: map
  @spec get_stats(t) :: list(transport_stat) | {:error, :terminated}
  @doc """
  Returns current RTC statistics of the pipe transport.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-getStats
  """
  def get_stats(%PipeTransport{pid: pid}) do
    GenServer.call(pid, {:get_stats, []})
  end

  @typedoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#TransportTuple
  """
  @type transport_tuple :: map

  @spec tuple(t) :: transport_tuple() | {:error, :terminated}
  @doc """
  The transport tuple. It refers to both RTP and RTCP since pipe transports use RTCP-mux by design.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-tuple
  """
  def tuple(%PipeTransport{pid: pid}) do
    GenServer.call(pid, {:tuple, []})
  end

  @spec sctp_parameters(Mediasoup.PipeTransport.t()) ::
          sctp_parameters_t() | {:error, :terminated}
  @doc """
  Local SCTP parameters. Or undefined if SCTP is not enabled.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-sctpParameters
  """
  def sctp_parameters(%PipeTransport{pid: pid}) do
    GenServer.call(pid, {:sctp_parameters, []})
  end

  @spec srtp_parameters(Mediasoup.PipeTransport.t()) ::
          srtp_parameters_t() | {:error, :terminated}
  @doc """
  Local SRTP parameters representing the crypto suite and key material used to encrypt sending RTP and SRTP.
  Those parameters must be given to the paired pipeTransport in the connect() method.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-srtpParameters
  """
  def srtp_parameters(%PipeTransport{pid: pid}) do
    GenServer.call(pid, {:srtp_parameters, []})
  end

  @spec sctp_state(Mediasoup.PipeTransport.t()) :: String.t() | {:error, :terminated}
  @doc """
  Current SCTP state. Or undefined if SCTP is not enabled.
  https://mediasoup.org/documentation/v3/mediasoup/api/#pipeTransport-sctpState
  """
  def sctp_state(%PipeTransport{pid: pid}) do
    GenServer.call(pid, {:sctp_state, []})
  end

  @spec dump(t) :: any | {:error, :terminated}
  @doc """
  Dump internal stat for PipeTransport.
  """
  def dump(%PipeTransport{pid: pid}) do
    GenServer.call(pid, {:dump, []})
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
    GenServer.call(pid, {:event, [listener, event_types]})
  end

  @spec struct_from_pid(pid()) :: PipeTransport.t()
  def struct_from_pid(pid) do
    GenServer.call(pid, {:struct_from_pid, []})
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
        pid when is_pid(pid) -> Nif.pipe_transport_event(reference, pid, event_types)
      end

    {:reply, result, state}
  end

  def handle_call(
        {:struct_from_pid, _arg},
        _from,
        %{reference: reference} = state
      ) do
    {:reply,
     %PipeTransport{
       pid: self(),
       id: Nif.pipe_transport_id(reference)
     }, state}
  end

  NifWrap.def_handle_call_nif(%{
    close: &Nif.pipe_transport_close/1,
    dump: &Nif.pipe_transport_dump/1,
    get_stats: &Nif.pipe_transport_get_stats/1,
    sctp_state: &Nif.pipe_transport_sctp_state/1,
    connect: &Nif.pipe_transport_connect/2,
    tuple: &Nif.pipe_transport_tuple/1,
    sctp_parameters: &Nif.pipe_transport_sctp_parameters/1,
    srtp_parameters: &Nif.pipe_transport_srtp_parameters/1
  })

  def handle_call(
        {:produce, [option]},
        _from,
        %{reference: reference, supervisor: supervisor} = state
      ) do
    ret =
      Nif.pipe_transport_produce(reference, option)
      |> NifWrap.handle_create_result(Producer, supervisor)

    {:reply, ret, state}
  end

  def handle_call(
        {:consume, [option]},
        _from,
        %{reference: reference, supervisor: supervisor} = state
      ) do
    ret =
      Nif.pipe_transport_consume(reference, option)
      |> NifWrap.handle_create_result(Consumer, supervisor)

    {:reply, ret, state}
  end

  def terminate(reason, %{reference: reference, supervisor: supervisor} = _state) do
    DynamicSupervisor.stop(supervisor, reason)
    Nif.pipe_transport_close(reference)
    :ok
  end
end

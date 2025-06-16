defmodule Mediasoup.DataProducer do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#DataProducer
  """

  require Logger
  alias Mediasoup.{DataProducer, NifWrap, Nif, EventListener}
  require NifWrap
  use GenServer, restart: :temporary

  @enforce_keys [:id, :type, :sctp_stream_parameters, :pid]
  defstruct [:id, :type, :sctp_stream_parameters, :pid]

  @type t :: %DataProducer{
          id: String.t(),
          type: dataProducerType,
          sctp_stream_parameters: sctpStreamParameters,
          pid: pid()
        }

  @type sctpStreamParameters :: map

  @typedoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#dataProducer-type
   "sctp" or "direct"
  """
  @type dataProducerType :: String.t()

  @spec id(t) :: String.t()
  def id(%{id: id}) do
    id
  end

  @spec type(t) :: dataProducerType
  def type(%{type: type}) do
    type
  end

  @spec sctp_stream_parameters(t) :: sctpStreamParameters
  def sctp_stream_parameters(%{sctp_stream_parameters: sctp_stream_parameters}) do
    sctp_stream_parameters
  end

  @spec close(t) :: :ok
  def close(%DataProducer{pid: pid}) do
    GenServer.stop(pid)
  end

  @spec closed?(t) :: boolean
  def closed?(%DataProducer{pid: pid}) do
    !Process.alive?(pid) || NifWrap.call(pid, {:closed?, []})
  end

  @type event_type :: :on_close
  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  def event(%DataProducer{pid: pid}, listener, event_types \\ [:on_close]) do
    NifWrap.call(pid, {:event, listener, event_types})
  end

  @spec struct_from_pid(pid()) :: DataProducer.t()
  def struct_from_pid(pid) when is_pid(pid) do
    GenServer.call(pid, {:struct_from_pid, []})
  end

  def struct_from_pid_and_ref(pid, reference) do
    %DataProducer{
      pid: pid,
      id: Nif.data_producer_id(reference),
      type: Nif.data_producer_type(reference),
      sctp_stream_parameters: Nif.data_producer_sctp_stream_parameters(reference)
    }
  end

  # GenServer callbacks
  def start_link(opt) do
    reference = Keyword.fetch!(opt, :reference)
    GenServer.start_link(__MODULE__, %{reference: reference}, opt)
  end

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, Map.merge(state, %{listeners: EventListener.new(), linked_consumer: nil})}
  end

  @impl true
  def handle_cast(
        {:link_pipe_consumer, consumer_pid},
        %{listeners: listeners, linked_consumer: nil} = state
      ) do
    # Pipe events from the Consumer to Producer.
    consumer_pid_ref = Process.monitor(consumer_pid)

    new_state =
      Map.merge(state, %{
        listeners: listeners,
        linked_consumer: %{pid: consumer_pid, monitor_ref: consumer_pid_ref}
      })

    {:noreply, new_state}
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
        {:DOWN, monitor_ref, :process, pid, reason},
        %{listeners: listeners, linked_consumer: linked_consumer} = state
      ) do
    if linked_consumer != nil and linked_consumer.pid == pid and
         linked_consumer.monitor_ref == monitor_ref do
      {:stop, reason, state}
    else
      listeners = EventListener.remove(listeners, pid)
      {:noreply, %{state | listeners: listeners}}
    end
  end

  @impl true
  def handle_info({:on_close}, state) do
    # piped event
    # Terminating a piped Producer/Consumer using on_close message sending is discouraged. Instead, use link_pipe_producer to link the processes.
    Logger.warning("deprecated: on_close")
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    # shutdown linked pipe consumer
    {:stop, reason, state}
  end

  @impl true
  def handle_info({:nif_internal_event, :on_close}, state) do
    {:stop, :normal, state}
  end

  NifWrap.def_handle_call_nif(%{
    closed?: &Nif.data_producer_closed/1
  })

  @impl true
  def terminate(_reason, %{reference: reference, listeners: listeners} = _state) do
    EventListener.send(listeners, :on_close, {:on_close})
    Nif.data_producer_close(reference)
    :ok
  end

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#DataProducerOptions
    """

    @enforce_keys []
    defstruct sctp_stream_parameters: nil,
              label: nil,
              protocol: nil

    @type t :: %Options{
            label: String.t() | nil,
            protocol: String.t() | nil,
            sctp_stream_parameters: DataProducer.sctpStreamParameters() | nil
          }

    @spec from_map(map) :: Mediasoup.DataProducer.Options.t()
    def from_map(%{} = map) do
      map = for {key, val} <- map, into: %{}, do: {to_string(key), val}

      %Options{
        label: map["label"],
        protocol: map["protocol"],
        sctp_stream_parameters: map["sctpStreamParameters"]
      }
    end
  end
end

defmodule Mediasoup.DataConsumer do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#DataConsumer
  """
  alias Mediasoup.{DataConsumer, NifWrap, Nif, EventListener}
  require NifWrap
  use GenServer, restart: :temporary

  @enforce_keys [:id, :data_producer_id, :type, :sctp_stream_parameters]
  defstruct [:id, :data_producer_id, :type, :sctp_stream_parameters, :label, :protocol, :pid]

  @type t :: %DataConsumer{
          id: String.t(),
          data_producer_id: String.t(),
          type: type,
          sctp_stream_parameters: sctpStreamParameters,
          label: String.t(),
          protocol: String.t(),
          pid: pid
        }

  @typedoc """
  https://mediasoup.org/documentation/v3/mediasoup/sctp-parameters/#SctpStreamParameters
  """
  @type sctpStreamParameters :: map

  @typedoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#DataConsumerType
   "sctp" or "direct"
  """
  @type type :: String.t()

  @spec id(t) :: String.t()
  def id(%{id: id}) do
    id
  end

  @spec data_producer_id(t) :: String.t()
  def data_producer_id(%{data_producer_id: data_producer_id}) do
    data_producer_id
  end

  @spec type(t) :: type
  def type(%{type: type}) do
    type
  end

  @spec sctp_stream_parameters(t) :: sctpStreamParameters
  def sctp_stream_parameters(%{sctp_stream_parameters: sctp_stream_parameters}) do
    sctp_stream_parameters
  end

  @spec label(t) :: String.t()
  def label(%{label: label}) do
    label
  end

  @spec protocol(t) :: String.t()
  def protocol(%{protocol: protocol}) do
    protocol
  end

  @spec close(t) :: :ok
  def close(%DataConsumer{pid: pid}) do
    GenServer.stop(pid)
  end

  @spec closed?(t) :: boolean
  def closed?(%DataConsumer{pid: pid}) do
    !Process.alive?(pid) || NifWrap.call(pid, {:closed?, []})
  end

  @type event_type :: :on_close
  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  def event(%DataConsumer{pid: pid}, listener, event_types \\ [:on_close]) do
    NifWrap.call(pid, {:event, listener, event_types})
  end

  def link_pipe_producer(%DataConsumer{pid: pid}, %Mediasoup.DataProducer{pid: producer_pid}) do
    GenServer.cast(pid, {:link_pipe_producer, producer_pid})
    GenServer.cast(producer_pid, {:link_pipe_consumer, pid})
  end

  @spec struct_from_pid(pid()) :: DataConsumer.t()
  def struct_from_pid(pid) when is_pid(pid) do
    GenServer.call(pid, {:struct_from_pid, []})
  end

  def struct_from_pid_and_ref(pid, reference) do
    %DataConsumer{
      pid: pid,
      id: Nif.data_consumer_id(reference),
      data_producer_id: Nif.data_consumer_producer_id(reference),
      type: Nif.data_consumer_type(reference),
      sctp_stream_parameters: Nif.data_consumer_sctp_stream_parameters(reference),
      label: Nif.data_consumer_label(reference),
      protocol: Nif.data_consumer_protocol(reference)
    }
  end

  # GenServer callbacks

  def start_link(opt) do
    reference = Keyword.fetch!(opt, :reference)
    GenServer.start_link(__MODULE__, %{reference: reference}, opt)
  end

  @impl true
  def init(%{reference: reference} = state) do
    Process.flag(:trap_exit, true)

    Nif.data_consumer_event(reference, self(), [
      :on_close
    ])

    {:ok, Map.merge(state, %{listeners: EventListener.new(), linked_producer: nil})}
  end

  @impl true
  def handle_cast(
        {:link_pipe_producer, producer_pid},
        %{listeners: listeners, linked_producer: nil} = state
      ) do
    # Pipe events from the pipe Producer to the pipe Consumer.
    listeners = EventListener.add(listeners, producer_pid, [:on_pause, :on_resume])
    producer_monitor_ref = Process.monitor(producer_pid)

    new_state =
      Map.merge(state, %{
        listeners: listeners,
        linked_producer: %{pid: producer_pid, monitor_ref: producer_monitor_ref}
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

  NifWrap.def_handle_call_nif(%{
    closed?: &Nif.data_consumer_closed/1
  })

  @impl true
  def handle_info(
        {:DOWN, monitor_ref, :process, pid, reason},
        %{listeners: listeners, linked_producer: linked_producer} = state
      ) do
    if linked_producer != nil and linked_producer.pid == pid and
         linked_producer.monitor_ref == monitor_ref do
      {:stop, reason, state}
    else
      listeners = EventListener.remove(listeners, pid)
      {:noreply, %{state | listeners: listeners}}
    end
  end

  @impl true
  def handle_info({:on_close}, state) do
    # piped event
    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    # shutdown linked pipe producer
    {:stop, reason, state}
  end

  @impl true
  def handle_info({:nif_internal_event, :on_close}, state) do
    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, %{reference: reference, listeners: listeners} = _state) do
    EventListener.send(listeners, :on_close, {:on_close})
    Nif.data_consumer_close(reference)
    :ok
  end

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#DataConsumerOptions
    """

    @enforce_keys [:data_producer_id]
    defstruct [:data_producer_id, ordered: nil, max_packet_life_time: nil, max_retransmits: nil]

    @type t :: %Options{
            data_producer_id: String.t(),
            ordered: boolean | nil,
            max_packet_life_time: integer | nil,
            max_retransmits: integer | nil
          }

    def from_map(%{} = map) do
      map = for {key, val} <- map, into: %{}, do: {to_string(key), val}

      %Options{
        data_producer_id: map["dataProducerId"],
        ordered: map["ordered"],
        max_packet_life_time: map["maxPacketLifeTime"],
        max_retransmits: map["maxRetransmits"]
      }
    end
  end
end

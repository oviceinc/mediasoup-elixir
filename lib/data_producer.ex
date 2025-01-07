defmodule Mediasoup.DataProducer do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#DataProducer
  """

  alias Mediasoup.{DataProducer, NifWrap, Nif}
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
    NifWrap.call(pid, {:event, [listener, event_types]})
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

  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  def handle_call({:event, [listener, event_types]}, _from, %{reference: reference} = state) do
    result =
      case NifWrap.EventProxy.wrap_if_remote_node(listener) do
        pid when is_pid(pid) -> Nif.data_producer_event(reference, pid, event_types)
      end

    {:reply, result, state}
  end

  def handle_call({:struct_from_pid, _arg}, _from, %{reference: reference} = state) do
    {:reply, struct_from_pid_and_ref(self(), reference), state}
  end

  def handle_info({:on_close}, state) do
    {:stop, :normal, state}
  end

  NifWrap.def_handle_call_nif(%{
    closed?: &Nif.data_producer_closed/1
  })

  def terminate(_reason, %{reference: reference} = _state) do
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

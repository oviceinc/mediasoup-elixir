defmodule Mediasoup.Consumer do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Consumer
  """
  alias Mediasoup.{Consumer, Nif}
  use Mediasoup.ProcessWrap.Base
  @enforce_keys [:id, :producer_id, :kind, :type, :rtp_parameters, :reference]
  defstruct [:id, :producer_id, :kind, :type, :rtp_parameters, :reference, :pid]

  @type t :: %Consumer{
          id: String.t(),
          producer_id: String.t(),
          kind: kind,
          type: type,
          rtp_parameters: rtpParameters,
          reference: reference | nil,
          pid: pid | nil
        }

  @type rtpParameters :: map

  @typedoc """
    audio or video
  """
  @type kind :: String.t()
  @type type :: String.t()

  def id(%Consumer{id: id}) do
    id
  end

  def producer_id(%Consumer{producer_id: producer_id}) do
    producer_id
  end

  def kind(%Consumer{kind: kind}) do
    kind
  end

  def type(%Consumer{type: type}) do
    type
  end

  def rtp_parameters(%Consumer{rtp_parameters: rtp_parameters}) do
    rtp_parameters
  end

  @spec close(t) :: {:ok} | {:error}
  def close(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.stop(pid)
  end

  def close(%Consumer{reference: reference}) do
    Nif.consumer_close(reference)
  end

  @spec dump(t) :: map | {:error}
  def dump(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:dump, []})
  end

  def dump(%Consumer{reference: reference}) do
    Nif.consumer_dump(reference)
  end

  @spec closed?(t) :: boolean
  def closed?(%Consumer{pid: pid}) when is_pid(pid) do
    !Process.alive?(pid) || GenServer.call(pid, {:closed?, []})
  end

  def closed?(%Consumer{reference: reference}) do
    Nif.consumer_closed(reference)
  end

  @spec paused?(t) :: boolean
  def paused?(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:paused?, []})
  end

  def paused?(%Consumer{reference: reference}) do
    Nif.consumer_paused(reference)
  end

  @spec producer_paused?(t) :: boolean
  def producer_paused?(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:producer_paused?, []})
  end

  def producer_paused?(%Consumer{reference: reference}) do
    Nif.consumer_producer_paused(reference)
  end

  @spec priority(t) :: number
  def priority(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:priority, []})
  end

  def priority(%Consumer{reference: reference}) do
    Nif.consumer_priority(reference)
  end

  @spec score(t) :: map
  def score(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:score, []})
  end

  def score(%Consumer{reference: reference}) do
    Nif.consumer_score(reference)
  end

  @spec preferred_layers(t) :: any
  def preferred_layers(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:preferred_layers, []})
  end

  def preferred_layers(%Consumer{reference: reference}) do
    Nif.consumer_preferred_layers(reference)
  end

  @spec current_layers(t) :: any
  def current_layers(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:current_layers, []})
  end

  def current_layers(%Consumer{reference: reference}) do
    Nif.consumer_current_layers(reference)
  end

  @spec get_stats(t) :: any
  def get_stats(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:get_stats, []})
  end

  def get_stats(%Consumer{reference: reference}) do
    Nif.consumer_get_stats(reference)
  end

  @spec pause(t) :: {:ok} | {:error}
  def pause(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:pause, []})
  end

  def pause(%Consumer{reference: reference}) do
    Nif.consumer_pause(reference)
  end

  @spec resume(t) :: {:ok} | {:error}
  def resume(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:resume, []})
  end

  def resume(%Consumer{reference: reference}) do
    Nif.consumer_resume(reference)
  end

  @spec set_preferred_layers(t, map) :: {:ok} | {:error}
  def set_preferred_layers(%Consumer{pid: pid}, layer) when is_pid(pid) do
    GenServer.call(pid, {:set_preferred_layers, [layer]})
  end

  def set_preferred_layers(%Consumer{reference: reference}, layer) do
    Nif.consumer_set_preferred_layers(reference, layer)
  end

  @spec set_priority(t, integer) :: {:ok} | {:error}
  def set_priority(%Consumer{pid: pid}, priority) when is_pid(pid) do
    GenServer.call(pid, {:set_priority, [priority]})
  end

  def set_priority(%Consumer{reference: reference}, priority) do
    Nif.consumer_set_priority(reference, priority)
  end

  @spec unset_priority(t) :: {:ok} | {:error}
  def unset_priority(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:unset_priority, []})
  end

  def unset_priority(%Consumer{reference: reference}) do
    Nif.consumer_unset_priority(reference)
  end

  @spec request_key_frame(t) :: {:ok} | {:error}
  def request_key_frame(%Consumer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:request_key_frame, []})
  end

  def request_key_frame(%Consumer{reference: reference}) do
    Nif.consumer_request_key_frame(reference)
  end

  @type event_type ::
          :on_close
          | :on_pause
          | :on_resume
          | :on_producer_resume
          | :on_producer_pause
          | :on_producer_close
          | :on_transport_close
          | :on_score
          | :on_layers_change

  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  def event(
        consumer,
        listener,
        event_types \\ [
          :on_close,
          :on_pause,
          :on_resume,
          :on_producer_resume,
          :on_producer_pause,
          :on_producer_close,
          :on_transport_close,
          :on_score,
          :on_layers_change
        ]
      )

  def event(%Consumer{pid: pid}, listener, event_types) when is_pid(pid) do
    GenServer.call(pid, {:event, [listener, event_types]})
  end

  def event(%Consumer{reference: reference}, pid, event_types) do
    Nif.consumer_event(reference, pid, event_types)
  end

  def handle_info({:on_close}, %{struct: struct} = state) do
    Consumer.close(struct)
    {:noreply, state}
  end

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#ConsumerOptions
    """
    @enforce_keys [:producer_id, :rtp_capabilities]
    defstruct [:producer_id, rtp_capabilities: nil, paused: nil, preferred_layers: nil, pipe: nil]

    @type t :: %Options{
            producer_id: String.t(),
            rtp_capabilities: map(),
            paused: boolean | nil,
            preferred_layers: term | nil,
            pipe: boolean | nil
          }

    def from_map(%{} = map) do
      map = for {key, val} <- map, into: %{}, do: {to_string(key), val}

      %Options{
        producer_id: map["producerId"],
        rtp_capabilities: map["rtpCapabilities"],
        paused: map["paused"],
        preferred_layers: map["preferredLayers"],
        pipe: map["pipe"]
      }
    end
  end
end

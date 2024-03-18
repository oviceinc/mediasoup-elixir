defmodule Mediasoup.Consumer do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Consumer
  """
  alias Mediasoup.{Consumer, NifWrap, Nif}
  require NifWrap
  use GenServer, restart: :temporary

  @enforce_keys [:id, :producer_id, :kind, :type, :rtp_parameters]
  defstruct [:id, :producer_id, :kind, :type, :rtp_parameters, :pid]

  @type t :: %Consumer{
          id: String.t(),
          producer_id: String.t(),
          kind: kind,
          type: type,
          rtp_parameters: rtpParameters,
          pid: pid
        }

  @typedoc """
  https://mediasoup.org/documentation/v3/mediasoup/rtp-parameters-and-capabilities/#RtpReceiveParameters
  """
  @type rtpParameters :: map

  @typedoc """
    MediaKind("audio" or "video")
  """
  @type kind :: String.t()

  @typedoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#ConsumerType
  """
  @type type :: String.t()

  @typedoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#ConsumerScore
  """
  @type consumer_score :: map

  @typedoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#ConsumerLayers
  """
  @type consumer_layers :: map

  @doc """
  Consumer identifier.
  """
  @spec id(t) :: String.t()
  def id(%{id: id}) do
    id
  end

  @doc """
  The associated producer identifier.
  """
  @spec producer_id(t) :: String.t()
  def producer_id(%{producer_id: producer_id}) do
    producer_id
  end

  @spec kind(t) :: kind
  @doc """
  The media kind
  """
  def kind(%{kind: kind}) do
    kind
  end

  @spec type(t) :: type
  @doc """
  Consumer type.
  https://mediasoup.org/documentation/v3/mediasoup/api/#ConsumerType
  """
  def type(%{type: type}) do
    type
  end

  @spec rtp_parameters(t) :: rtpParameters
  @doc """
  Consumer RTP parameters.
  """
  def rtp_parameters(%{rtp_parameters: rtp_parameters}) do
    rtp_parameters
  end

  @spec close(t) :: :ok
  @doc """
  Closes the consumer.
  """
  def close(%Consumer{pid: pid}) do
    GenServer.stop(pid)
  end

  @spec dump(t) :: map | {:error}
  @doc """
  Dump internal stat for Consumer.
  """
  def dump(%Consumer{pid: pid}) do
    GenServer.call(pid, {:dump, []})
  end

  @spec closed?(t) :: boolean
  @doc """
  Tells whether the given consumer is closed on the local node.
  """
  def closed?(%Consumer{pid: pid}) do
    !Process.alive?(pid) || GenServer.call(pid, {:closed?, []})
  end

  @spec paused?(t) :: boolean
  @doc """
  Whether the consumer is paused. It does not take into account whether the associated producer is paused.
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-paused
  """
  def paused?(%Consumer{pid: pid}) do
    GenServer.call(pid, {:paused?, []})
  end

  @spec producer_paused?(t) :: boolean
  @doc """
  Whether the associated producer is paused.
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-producerPaused
  """
  def producer_paused?(%Consumer{pid: pid}) do
    GenServer.call(pid, {:producer_paused?, []})
  end

  @spec priority(t) :: number
  @doc """
  Consumer priority (see set_priority/2).
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-priority
  """
  def priority(%Consumer{pid: pid}) do
    GenServer.call(pid, {:priority, []})
  end

  @spec score(t) :: consumer_score
  @doc """
  The score of the RTP stream being sent, representing its tranmission quality.
  """
  def score(%Consumer{pid: pid}) do
    GenServer.call(pid, {:score, []})
  end

  @spec preferred_layers(t) :: consumer_layers | nil
  @doc """
  Preferred spatial and temporal layers (see set_preferred_layers/2 method). For simulcast and SVC consumers, nil otherwise.
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-preferredLayers
  """
  def preferred_layers(%Consumer{pid: pid}) do
    GenServer.call(pid, {:preferred_layers, []})
  end

  @spec current_layers(t) :: consumer_layers | nil
  @doc """
  Currently active spatial and temporal layers (for simulcast and SVC consumers only).
  It's nil if no layers are being sent to the consuming endpoint at this time (or if the consumer is consuming from a simulcast or svc producer).
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-currentLayers
  """
  def current_layers(%Consumer{pid: pid}) do
    GenServer.call(pid, {:current_layers, []})
  end

  @spec get_stats(t) :: list(transport_stat) | {:error, reason :: term()}
  @doc """
  Returns current RTC statistics of the consumer.
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-getStats
  """
  def get_stats(%Consumer{pid: pid}) do
    GenServer.call(pid, {:get_stats, []})
  end

  @spec pause(t) :: {:ok} | {:error}
  @doc """
  Pauses the consumer (no RTP is sent to the consuming endpoint).
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-pause
  """
  def pause(%Consumer{pid: pid}) do
    GenServer.call(pid, {:pause, []})
  end

  @spec resume(t) :: {:ok} | {:error}
  @doc """
  Resumes the consumer (RTP is sent again to the consuming endpoint).
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-resume
  """
  def resume(%Consumer{pid: pid}) do
    GenServer.call(pid, {:resume, []})
  end

  @spec set_preferred_layers(t, map) :: {:ok} | {:error}
  @doc """
  Sets the preferred (highest) spatial and temporal layers to be sent to the consuming endpoint. Just valid for simulcast and SVC consumers.
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-setPreferredLayers
  """
  def set_preferred_layers(%Consumer{pid: pid}, layer) do
    GenServer.call(pid, {:set_preferred_layers, [layer]})
  end

  @spec set_priority(t, integer) :: {:ok} | {:error}
  @doc """
  Sets the priority for this consumer. It affects how the estimated outgoing bitrate in the transport (obtained via transport-cc or REMB) is distributed among all video consumers, by priorizing those with higher priority.
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-setPriority
  """
  def set_priority(%Consumer{pid: pid}, priority) do
    GenServer.call(pid, {:set_priority, [priority]})
  end

  @spec unset_priority(t) :: {:ok} | {:error}
  @doc """
  Unsets the priority for this consumer (it sets it to its default value 1).
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-unsetPriority
  """
  def unset_priority(%Consumer{pid: pid}) do
    GenServer.call(pid, {:unset_priority, []})
  end

  @spec request_key_frame(t) :: {:ok} | {:error}
  @doc """
  Request a key frame to the associated producer. Just valid for video consumers.
  https://mediasoup.org/documentation/v3/mediasoup/api/#consumer-requestKeyFrame
  """
  def request_key_frame(%Consumer{pid: pid}) do
    GenServer.call(pid, {:request_key_frame, []})
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
  @doc """
  Starts observing event.
  """
  def event(
        %Consumer{pid: pid},
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
      ) do
    GenServer.call(pid, {:event, [listener, event_types]})
  end

  @spec struct_from_pid(pid()) :: Consumer.t()
  def struct_from_pid(pid) when is_pid(pid) do
    GenServer.call(pid, {:struct_from_pid, []})
  end

  def struct_from_pid_and_ref(pid, reference) do
    %Consumer{
      pid: pid,
      id: Nif.consumer_id(reference),
      producer_id: Nif.consumer_producer_id(reference),
      kind: Nif.consumer_kind(reference),
      type: Nif.consumer_type(reference),
      rtp_parameters: Nif.consumer_rtp_parameters(reference)
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
    {:ok, state}
  end

  @impl true
  def handle_call(
        {:event, [listener, event_types]},
        _from,
        %{reference: reference} = state
      ) do
    result =
      case NifWrap.EventProxy.wrap_if_remote_node(listener) do
        pid when is_pid(pid) -> Nif.consumer_event(reference, pid, event_types)
      end

    {:reply, result, state}
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
    closed?: &Nif.consumer_closed/1,
    dump: &Nif.consumer_dump/1,
    paused?: &Nif.consumer_paused/1,
    producer_paused?: &Nif.consumer_producer_paused/1,
    priority: &Nif.consumer_priority/1,
    score: &Nif.consumer_score/1,
    preferred_layers: &Nif.consumer_preferred_layers/1,
    current_layers: &Nif.consumer_current_layers/1,
    get_stats: &Nif.consumer_get_stats/1,
    pause: &Nif.consumer_pause/1,
    resume: &Nif.consumer_resume/1,
    set_preferred_layers: &Nif.consumer_set_preferred_layers/2,
    set_priority: &Nif.consumer_set_priority/2,
    unset_priority: &Nif.consumer_unset_priority/1,
    request_key_frame: &Nif.consumer_request_key_frame/1
  })

  @impl true
  def handle_info({:on_close}, state) do
    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, %{reference: reference} = _state) do
    Nif.consumer_close(reference)
    :ok
  end

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#ConsumerOptions
    """
    @enforce_keys [:producer_id, :rtp_capabilities]
    defstruct [
      :producer_id,
      rtp_capabilities: nil,
      paused: nil,
      preferred_layers: nil,
      enable_rtx: nil,
      ignore_dtx: nil,
      pipe: nil,
      mid: nil
    ]

    @type t :: %Options{
            producer_id: String.t(),
            rtp_capabilities: map(),
            paused: boolean | nil,
            preferred_layers: term | nil,
            enable_rtx: boolean | nil,
            ignore_dtx: boolean | nil,
            pipe: boolean | nil,
            mid: String.t() | nil
          }

    def from_map(%{} = map) do
      map = for {key, val} <- map, into: %{}, do: {to_string(key), val}

      %Options{
        producer_id: map["producerId"],
        rtp_capabilities: map["rtpCapabilities"],
        paused: map["paused"],
        preferred_layers: map["preferredLayers"],
        enable_rtx: map["enableRtx"],
        ignore_dtx: map["ignoreDtx"],
        pipe: map["pipe"],
        mid: map["mid"]
      }
    end
  end
end

defmodule Mediasoup.Producer do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Producer
  """
  alias Mediasoup.{Producer, NifWrap, Nif}
  require NifWrap
  use GenServer, restart: :temporary

  @enforce_keys [:id, :kind, :type, :rtp_parameters, :pid]
  defstruct [:id, :kind, :type, :rtp_parameters, :pid]

  @type t ::
          %Producer{
            id: String.t(),
            kind: mediaKind,
            type: producerType,
            rtp_parameters: rtpParameters,
            pid: pid()
          }

  @type rtpParameters :: map

  @typedoc """
    audio or video
  """
  @type mediaKind :: String.t()
  @typedoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#ProducerType
    “simple” or “simulcast” or “svc”
  """
  @type producerType :: String.t()

  @spec id(t) :: String.t()
  @doc """
  Producer identifier.
  """
  def id(%{id: id}) do
    id
  end

  @spec kind(t) :: mediaKind
  @doc """
    The media kind
  """
  def kind(%{kind: kind}) do
    kind
  end

  @spec type(t) :: producerType
  @doc """
    Producer type.
    https://mediasoup.org/documentation/v3/mediasoup/api/#ProducerType
  """
  def type(%{type: type}) do
    type
  end

  @spec rtp_parameters(t) :: rtpParameters()
  @doc """
    RtpParameters.
    https://mediasoup.org/documentation/v3/mediasoup/rtp-parameters-and-capabilities/#RtpParameters
  """
  def rtp_parameters(%{rtp_parameters: rtp_parameters}) do
    rtp_parameters
  end

  @spec close(t) :: :ok
  @doc """
    Closes the producer. Triggers a “producerclose” event in all its associated consumers.
    https://mediasoup.org/documentation/v3/mediasoup/api/#producer-close
  """
  def close(%Producer{pid: pid}) do
    GenServer.stop(pid)
  end

  @spec dump(t) :: map
  @doc """
  Dump internal stat for Producer.
  """
  def dump(%Producer{pid: pid}) do
    GenServer.call(pid, {:dump, []})
  end

  @spec pause(t) :: {:ok} | {:error}
  @doc """
  Pauses the producer (no RTP is sent to its associated consumers). Triggers a “producerpause” event in all its associated consumers.
  https://mediasoup.org/documentation/v3/mediasoup/api/#producer-pause
  """
  def pause(%Producer{pid: pid}) do
    GenServer.call(pid, {:pause, []})
  end

  @spec resume(t) :: {:ok} | {:error}
  @doc """
  Resumes the producer (RTP is sent again to its associated consumers). Triggers a “producerresume” event in all its associated consumers.
  https://mediasoup.org/documentation/v3/mediasoup/api/#producer-resume
  """
  def resume(%Producer{pid: pid}) do
    GenServer.call(pid, {:resume, []})
  end

  @spec score(t) :: list() | {:error}
  @doc """
  The score of each RTP stream being received, representing their tranmission quality.
  https://mediasoup.org/documentation/v3/mediasoup/api/#producer-score
  """
  def score(%Producer{pid: pid}) do
    GenServer.call(pid, {:score, []})
  end

  @spec get_stats(t) :: list() | {:error, reason :: term()}
  @doc """
  Returns current RTC statistics of the producer.
  Check the [RTC Statistics](https://mediasoup.org/documentation/v3/mediasoup/rtc-statistics/)
  section for more details (TypeScript-oriented, but concepts apply here as well).
  """
  def get_stats(%Producer{pid: pid}) do
    GenServer.call(pid, {:get_stats, []})
  end

  @spec closed?(t) :: boolean()
  @doc """
  Tells whether the given producer is closed on the local node.
  """
  def closed?(%Producer{pid: pid}) do
    !Process.alive?(pid) || GenServer.call(pid, {:closed?, []})
  end

  @spec paused?(t) :: boolean() | {:error}
  @doc """
  Whether the producer is paused.
  https://mediasoup.org/documentation/v3/mediasoup/api/#producer-paused
  """
  def paused?(%Producer{pid: pid}) do
    GenServer.call(pid, {:paused?, []})
  end

  @type event_type ::
          :on_close
          | :on_pause
          | :on_resume
          | :on_video_orientation_change
          | :on_score

  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  @doc """
  Starts observing event.
  """
  def event(
        %Producer{pid: pid},
        listener,
        event_types \\ [
          :on_close,
          :on_pause,
          :on_resume,
          :on_video_orientation_change,
          :on_score
        ]
      ) do
    GenServer.call(pid, {:event, [listener, event_types]})
  end

  @spec struct_from_pid(pid()) :: Producer.t()
  def struct_from_pid(pid) when is_pid(pid) do
    GenServer.call(pid, {:struct_from_pid, []})
  end

  def struct_from_pid_and_ref(pid, reference) do
    %Producer{
      pid: pid,
      id: Nif.producer_id(reference),
      kind: Nif.producer_kind(reference),
      type: Nif.producer_type(reference),
      rtp_parameters: Nif.producer_rtp_parameters(reference)
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
        pid when is_pid(pid) -> Nif.producer_event(reference, pid, event_types)
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
    closed?: &Nif.producer_closed/1,
    paused?: &Nif.producer_paused/1,
    score: &Nif.producer_score/1
  })

  NifWrap.def_handle_call_async_nif(%{
    pause: &Nif.producer_pause_async/2,
    resume: &Nif.producer_resume_async/2,
    get_stats: &Nif.producer_get_stats_async/2,
    dump: &Nif.producer_dump_async/2
  })

  @impl true
  def handle_info(
        {:mediasoup_async_nif_result, nil, _},
        state
      ) do
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
  def handle_info({:on_resume}, %{reference: reference} = state) do
    Nif.producer_resume_async(reference, nil)
    {:noreply, state}
  end

  @impl true
  def handle_info({:on_pause}, %{reference: reference} = state) do
    Nif.producer_pause_async(reference, nil)
    {:noreply, state}
  end

  @impl true
  def handle_info({:on_close}, state) do
    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, %{reference: reference} = _state) do
    Nif.producer_close(reference)
    :ok
  end

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#ProducerOptions
    """

    @enforce_keys [:rtp_parameters]
    defstruct [
      :rtp_parameters,
      id: nil,
      kind: nil,
      paused: nil,
      key_frame_request_delay: nil
    ]

    @type t :: %Options{
            id: String.t() | nil,
            kind: :audio | :video | nil,
            rtp_parameters: Producer.rtpParameters(),
            paused: boolean | nil,
            key_frame_request_delay: integer | nil
          }

    @spec from_map(map) :: Mediasoup.Producer.Options.t()
    def from_map(%{} = map) do
      map = for {key, val} <- map, into: %{}, do: {to_string(key), val}

      %Options{
        id: map["id"],
        kind: map["kind"],
        rtp_parameters: map["rtpParameters"],
        paused: map["paused"],
        key_frame_request_delay: map["keyFrameRequestDelay"]
      }
    end
  end
end

defmodule Mediasoup.PipedProducer do
  @moduledoc """
  @deprecated Remove soom.
  """
  alias Mediasoup.Producer

  @doc """
  @deprecated Remove soom.
  """
  def into_producer(%Producer{} = producer) do
    {:ok, producer}
  end
end

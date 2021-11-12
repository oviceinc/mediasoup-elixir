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
            kind: kind,
            type: type,
            rtp_parameters: rtpParameters,
            pid: pid()
          }

  @type rtpParameters :: map

  @typedoc """
    audio or video
  """
  @type kind :: String.t()
  @type type :: String.t()

  @spec id(t) :: String.t()
  def id(%{id: id}) do
    id
  end

  @spec kind(t) :: String.t()
  def kind(%{kind: kind}) do
    kind
  end

  @spec type(t) :: String.t()
  def type(%{type: type}) do
    type
  end

  @spec rtp_parameters(t) :: rtpParameters()
  def rtp_parameters(%{rtp_parameters: rtp_parameters}) do
    rtp_parameters
  end

  @spec close(t) :: :ok
  def close(%Producer{pid: pid}) do
    GenServer.stop(pid)
  end

  @spec dump(t) :: map
  def dump(%Producer{pid: pid}) do
    GenServer.call(pid, {:dump, []})
  end

  @spec pause(t) :: {:ok} | {:error}
  def pause(%Producer{pid: pid}) do
    GenServer.call(pid, {:pause, []})
  end

  @spec resume(t) :: {:ok} | {:error}
  def resume(%Producer{pid: pid}) do
    GenServer.call(pid, {:resume, []})
  end

  @spec score(t) :: list() | {:error}
  def score(%Producer{pid: pid}) do
    GenServer.call(pid, {:score, []})
  end

  @spec get_stats(t) :: list() | {:error}
  def get_stats(%Producer{pid: pid}) do
    GenServer.call(pid, {:get_stats, []})
  end

  @spec closed?(t) :: boolean()
  def closed?(%Producer{pid: pid}) do
    !Process.alive?(pid) || GenServer.call(pid, {:closed?, []})
  end

  @spec paused?(t) :: boolean() | {:error}
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

  # GenServer callbacks

  def start_link(opt) do
    reference = Keyword.fetch!(opt, :reference)
    GenServer.start_link(__MODULE__, %{reference: reference}, opt)
  end

  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

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

  def handle_call(
        {:struct_from_pid, _arg},
        _from,
        %{reference: reference} = state
      ) do
    {:reply,
     %Producer{
       pid: self(),
       id: Nif.producer_id(reference),
       kind: Nif.producer_kind(reference),
       type: Nif.producer_type(reference),
       rtp_parameters: Nif.producer_rtp_parameters(reference)
     }, state}
  end

  NifWrap.def_handle_call_nif(%{
    closed?: &Nif.producer_closed/1,
    dump: &Nif.producer_dump/1,
    paused?: &Nif.producer_paused/1,
    score: &Nif.producer_score/1,
    get_stats: &Nif.producer_get_stats/1,
    pause: &Nif.producer_pause/1,
    resume: &Nif.producer_resume/1
  })

  def handle_info({:on_resume}, %{reference: reference} = state) do
    Nif.producer_resume(reference)
    {:noreply, state}
  end

  def handle_info({:on_pause}, %{reference: reference} = state) do
    Nif.producer_pause(reference)
    {:noreply, state}
  end

  def handle_info({:on_close}, state) do
    {:stop, :normal, state}
  end

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

  def into_producer(%Producer{} = producer) do
    {:ok, producer}
  end
end

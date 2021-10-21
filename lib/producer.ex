defmodule Mediasoup.Producer do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Producer
  """
  alias Mediasoup.{Producer, Nif}
  use Mediasoup.ProcessWrap.Base
  @enforce_keys [:id, :kind, :type, :rtp_parameters, :reference, :pid]
  defstruct [:id, :kind, :type, :rtp_parameters, :reference, :pid]

  @type t :: %Producer{
          id: String.t(),
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

  def id(%Producer{id: id}) do
    id
  end

  @spec kind(t) :: String.t()
  def kind(%Producer{kind: kind}) do
    kind
  end

  @spec type(t) :: String.t()
  def type(%Producer{type: type}) do
    type
  end

  @spec rtp_parameters(t) :: rtpParameters()
  def rtp_parameters(%Producer{rtp_parameters: rtp_parameters}) do
    rtp_parameters
  end

  @spec close(t) :: {:ok} | {:error}
  def close(%Producer{pid: pid}) when is_pid(pid) do
    GenServer.stop(pid)
  end

  def close(%Producer{reference: reference}) do
    Nif.producer_close(reference)
  end

  @spec dump(t) :: map
  def dump(%Producer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:dump, []})
  end

  def dump(%Producer{reference: reference}) do
    Nif.producer_dump(reference)
  end

  @spec pause(t) :: {:ok} | {:error}
  def pause(%Producer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:pause, []})
  end

  def pause(%Producer{reference: reference}) do
    Nif.producer_pause(reference)
  end

  @spec resume(t) :: {:ok} | {:error}
  def resume(%Producer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:resume, []})
  end

  def resume(%Producer{reference: reference}) do
    Nif.producer_resume(reference)
  end

  @spec score(t) :: list() | {:error}
  def score(%Producer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:score, []})
  end

  def score(%Producer{reference: reference}) do
    Nif.producer_score(reference)
  end

  @spec get_stats(t) :: list() | {:error}
  def get_stats(%Producer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:get_stats, []})
  end

  def get_stats(%Producer{reference: reference}) do
    Nif.producer_get_stats(reference)
  end

  @spec closed?(t) :: boolean()
  def closed?(%Producer{pid: pid}) when is_pid(pid) do
    !Process.alive?(pid) || GenServer.call(pid, {:closed?, []})
  end

  def closed?(%Producer{reference: reference}) do
    Nif.producer_closed(reference)
  end

  @spec paused?(t) :: boolean() | {:error}
  def paused?(%Producer{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:paused?, []})
  end

  def paused?(%Producer{reference: reference}) do
    Nif.producer_paused(reference)
  end

  @type event_type ::
          :on_close
          | :on_pause
          | :on_resume
          | :on_video_orientation_change
          | :on_score

  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  def event(
        producer,
        listener,
        event_types \\ [
          :on_close,
          :on_pause,
          :on_resume,
          :on_video_orientation_change,
          :on_score
        ]
      )

  def event(%Producer{pid: pid}, listener, event_types) when is_pid(pid) do
    GenServer.call(pid, {:event, [listener, event_types]})
  end

  def event(%Producer{reference: reference}, pid, event_types) do
    Nif.producer_event(reference, pid, event_types)
  end

  def handle_info({:on_resume}, %{struct: struct} = state) do
    Producer.resume(struct)
    {:noreply, state}
  end

  def handle_info({:on_pause}, %{struct: struct} = state) do
    Producer.pause(struct)
    {:noreply, state}
  end

  def handle_info({:on_close}, %{struct: struct} = state) do
    Producer.close(struct)
    {:noreply, state}
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
  https://mediasoup.org/documentation/v3/mediasoup/api/#Producer
  Same as [`Producer`], but will not be closed when gc.
  """
  alias Mediasoup.{Producer, PipedProducer, Nif}
  @enforce_keys [:reference]
  defstruct [:reference]

  @type t :: %PipedProducer{
          reference: reference
        }

  @spec into_producer(t | Producer.t()) :: {:ok, Producer.t()} | {:error, message :: term}
  def into_producer(%PipedProducer{reference: reference}) do
    Nif.piped_producer_into_producer(reference)
  end

  def into_producer(%Producer{} = producer) do
    {:ok, producer}
  end
end

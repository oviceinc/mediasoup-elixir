defmodule Mediasoup.Router do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Router
  """
  alias Mediasoup.{Router, WebRtcTransport, PipeTransport, Nif}
  use Mediasoup.ProcessWrap.WithChildren

  @enforce_keys [:id]
  defstruct [:id, :reference, :pid]
  @type t :: %Router{id: String.t(), reference: reference | nil, pid: pid | nil}

  @type rtpCapabilities :: map

  @type create_option :: map

  defmodule PipeToRouterOptions do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#PipeToRouterOptions
    without producerId.
    producerId is the argument of the function
    """
    @type num_sctp_streams :: %{OS: integer(), MIS: integer()}

    @enforce_keys [:router]
    defstruct [
      :router,
      enable_sctp: nil,
      num_sctp_streams: nil,
      enable_rtx: nil,
      enable_srtp: nil
    ]

    @type t :: %PipeToRouterOptions{
            router: Mediasoup.Router.t(),
            enable_sctp: boolean() | nil,
            num_sctp_streams: num_sctp_streams() | nil,
            enable_rtx: boolean() | nil,
            enable_srtp: boolean() | nil
          }
  end

  defmodule PipeToRouterResult do
    defstruct pipe_consumer: nil, pipe_producer: nil

    @type t :: %PipeToRouterResult{
            pipe_consumer: Mediasoup.Consumer.t() | nil,
            pipe_producer: Mediasoup.PipedProducer.t() | nil
          }
  end

  def id(%Router{id: id}) do
    id
  end

  @spec close(t) :: {:ok} | {:error}
  def close(%Router{pid: pid}) when is_pid(pid) do
    GenServer.stop(pid)
  end

  def close(%Router{reference: reference}) do
    Nif.router_close(reference)
  end

  @spec closed?(t) :: boolean
  def closed?(%Router{pid: pid}) when is_pid(pid) do
    !Process.alive?(pid) || GenServer.call(pid, {:closed?, []})
  end

  def closed?(%Router{reference: reference}) do
    Nif.router_closed(reference)
  end

  @spec create_webrtc_transport(t, WebRtcTransport.create_option()) ::
          {:ok, WebRtcTransport.t()} | {:error, String.t()}
  def create_webrtc_transport(
        %Router{pid: pid},
        %WebRtcTransport.Options{} = option
      )
      when is_pid(pid) do
    GenServer.call(pid, {:start_child, WebRtcTransport, :create_webrtc_transport, [option]})
  end

  def create_webrtc_transport(%Router{reference: reference}, %WebRtcTransport.Options{} = option) do
    Nif.router_create_webrtc_transport(reference, option)
  end

  def create_webrtc_transport(router, %{} = option) do
    create_webrtc_transport(router, WebRtcTransport.Options.from_map(option))
  end

  @spec pipe_producer_to_router(t, producer_id :: String.t(), PipeToRouterOptions.t()) ::
          {:ok, PipeToRouterResult.t()} | {:error, String.t()}
  def pipe_producer_to_router(
        %Router{pid: pid},
        producer_id,
        %PipeToRouterOptions{} = option
      )
      when is_pid(pid) do
    GenServer.call(pid, {:pipe_producer_to_router, [producer_id, option]})
  end

  def pipe_producer_to_router(
        router,
        producer_id,
        %PipeToRouterOptions{router: %Router{pid: pid}} = option
      )
      when is_pid(pid) do
    # need check same node
    router_struct = Router.struct(pid)

    pipe_producer_to_router(router, producer_id, %{
      option
      | router: router_struct
    })
  end

  def pipe_producer_to_router(
        %Router{reference: reference},
        producer_id,
        %PipeToRouterOptions{} = option
      ) do
    Nif.router_pipe_producer_to_router(reference, producer_id, option)
  end

  @spec create_pipe_transport(
          Router.t(),
          PipeTransport.Options.t()
        ) :: {:ok, PipeTransport.t()} | {:error, String.t()}
  def create_pipe_transport(%Router{pid: pid}, %PipeTransport.Options{} = option)
      when is_pid(pid) do
    GenServer.call(pid, {:start_child, PipeTransport, :create_pipe_transport, [option]})
  end

  def create_pipe_transport(
        %Router{reference: reference},
        %PipeTransport.Options{} = option
      ) do
    Nif.router_create_pipe_transport(reference, option)
  end

  @spec can_consume?(t, String.t(), rtpCapabilities) :: boolean
  def can_consume?(%Router{pid: pid}, producer_id, rtp_capabilities) when is_pid(pid) do
    GenServer.call(pid, {:can_consume?, [producer_id, rtp_capabilities]})
  end

  def can_consume?(%Router{reference: reference}, producer_id, rtp_capabilities) do
    Nif.router_can_consume(reference, producer_id, rtp_capabilities)
  end

  @spec rtp_capabilities(t) :: Router.rtpCapabilities()
  def rtp_capabilities(%Router{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:rtp_capabilities, []})
  end

  def rtp_capabilities(%Router{reference: reference}) do
    Nif.router_rtp_capabilities(reference)
  end

  @spec dump(t) :: map | {:error}
  def dump(%Router{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:dump, []})
  end

  def dump(%Router{reference: reference}) do
    Nif.router_dump(reference)
  end

  @type event_type ::
          :on_close
          | :on_dead

  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  def event(
        router,
        listener,
        event_types \\ [
          :on_close,
          :on_dead
        ]
      )

  def event(%Router{pid: pid}, listener, event_types) when is_pid(pid) do
    GenServer.call(pid, {:event, [listener, event_types]})
  end

  def event(%Router{reference: reference}, pid, event_types) do
    Nif.router_event(reference, pid, event_types)
  end
end

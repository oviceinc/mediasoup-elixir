defmodule Mediasoup.Router do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Router
  """
  alias Mediasoup.{Router, WebRtcTransport, Nif}
  @enforce_keys [:id, :reference]
  defstruct [:id, :reference]
  @type t(id, ref) :: %Router{id: id, reference: ref}
  @type t :: %Router{id: String.t(), reference: reference}

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

  @spec close(t) :: {:ok} | {:error}
  def close(%Router{reference: reference}) do
    Nif.router_close(reference)
  end

  @spec create_webrtc_transport(t, WebRtcTransport.create_option()) ::
          {:ok, WebRtcTransport.t()} | {:error, String.t()}
  def create_webrtc_transport(%Router{reference: reference}, %WebRtcTransport.Options{} = option) do
    Nif.router_create_webrtc_transport(reference, option)
  end

  def create_webrtc_transport(router, %{} = option) do
    create_webrtc_transport(router, WebRtcTransport.Options.from_map(option))
  end

  @spec pipe_producer_to_router(t, producer_id :: String.t(), PipeToRouterOptions.t()) ::
          {:ok, PipeToRouterResult.t()} | {:error, String.t()}
  def pipe_producer_to_router(
        %Router{reference: reference},
        producer_id,
        %PipeToRouterOptions{} = option
      ) do
    Nif.router_pipe_producer_to_router(reference, producer_id, option)
  end

  @spec can_consume?(t, String.t(), rtpCapabilities) :: boolean
  def can_consume?(%Router{reference: reference}, producer_id, rtp_capabilities) do
    Nif.router_can_consume(reference, producer_id, rtp_capabilities)
  end

  @spec rtp_capabilities(t) :: Router.rtpCapabilities()
  def rtp_capabilities(%Router{reference: reference}) do
    Nif.router_rtp_capabilities(reference)
  end

  @spec dump(t) :: map | {:error}
  def dump(%Router{reference: reference}) do
    Nif.router_dump(reference)
  end

  @spec event(t, pid) :: {:ok} | {:error}
  def event(%Router{reference: reference}, pid) do
    Nif.router_event(reference, pid)
  end
end

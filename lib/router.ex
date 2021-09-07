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

  @spec close(t) :: {:ok} | {:error}
  def close(%Router{reference: reference}) do
    Nif.router_close(reference)
  end

  @spec create_webrtc_transport(t, WebRtcTransport.create_option()) ::
          {:ok, WebRtcTransport.t()} | {:error, String.t()}
  def create_webrtc_transport(%Router{reference: reference}, option) do
    Nif.router_create_webrtc_transport(reference, option)
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

defmodule Mediasoup.Router do
  alias Mediasoup.{Router, WebRtcTransport, Nif}
  @enforce_keys [:id, :reference]
  defstruct [:id, :reference]
  @type t(id, ref) :: %Router{id: id, reference: ref}
  @type t :: %Router{id: String.t(), reference: reference}

  @type create_option :: map

  @spec close(t) :: {:ok} | {:error}
  def close(router) do
    Nif.router_close(router.reference)
  end

  @spec create_webrtc_transport(t, WebRtcTransport.create_option()) ::
          {:ok, WebRtcTransport.t()} | {:error}
  def create_webrtc_transport(router, option) do
    Nif.router_create_webrtc_transport(router.reference, option)
  end

  @spec can_consume?(t, String.t(), list(any)) :: boolean
  def can_consume?(router, producer_id, rtp_capabilities) do
    Nif.router_can_consume(router.reference, producer_id, rtp_capabilities)
  end

  @spec dump(t) :: %{} | {:error}
  def dump(router) do
    Nif.router_dump(router.reference)
  end

  @spec event(t, pid) :: {:ok} | {:error}
  def event(router, pid) do
    Nif.router_event(router.reference, pid)
  end
end

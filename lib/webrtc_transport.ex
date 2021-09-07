defmodule Mediasoup.WebRtcTransport do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#WebRtcTransport
  """

  alias Mediasoup.{WebRtcTransport, Nif, Consumer, Producer}
  @enforce_keys [:id, :reference]
  defstruct [:id, :reference]
  @type t(id, ref) :: %WebRtcTransport{id: id, reference: ref}
  @type t :: %WebRtcTransport{id: String.t(), reference: reference}

  @type create_option :: map

  @type consume_option :: map
  @type produce_option :: map
  @type connect_option :: map

  @type ice_parameter :: map()

  @spec close(t) :: {:ok} | {:error}
  def close(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_close(reference)
  end

  @spec consume(t, consume_option()) :: {:ok, Consumer.t()} | {:error, String.t() | :terminated}
  def consume(%WebRtcTransport{reference: reference}, option) do
    Nif.webrtc_transport_consume(reference, option)
  end

  @spec produce(t, produce_option()) :: {:ok, Producer.t()} | {:error, String.t() | :terminated}
  def produce(%WebRtcTransport{reference: reference}, option) do
    Nif.webrtc_transport_produce(reference, option)
  end

  @spec connect(t, connect_option()) :: {:ok} | {:error, String.t() | :terminated}
  def connect(%WebRtcTransport{reference: reference}, option) do
    Nif.webrtc_transport_connect(reference, option)
  end

  @spec ice_parameters(t) :: ice_parameter() | {:error, :terminated}
  def ice_parameters(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_ice_parameters(reference)
  end

  @spec sctp_parameters(t) :: map() | {:error, :terminated}
  def sctp_parameters(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_sctp_parameters(reference)
  end

  @spec ice_candidates(t) :: list(any)
  def ice_candidates(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_ice_candidates(reference)
  end

  @spec ice_role(t) :: String.t() | {:error, :terminated}
  def ice_role(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_ice_role(reference)
  end

  @spec set_max_incoming_bitrate(t, integer) :: {:ok} | {:error, :terminated}
  def set_max_incoming_bitrate(%WebRtcTransport{reference: reference}, bitrate) do
    Nif.webrtc_transport_set_max_incoming_bitrate(reference, bitrate)
  end

  @spec set_max_outgoing_bitrate(t, integer) :: {:ok} | {:error, :terminated}
  def set_max_outgoing_bitrate(%WebRtcTransport{reference: reference}, bitrate) do
    Nif.webrtc_transport_set_max_outgoing_bitrate(reference, bitrate)
  end

  @spec ice_state(t) :: String.t() | {:error, :terminated}
  def ice_state(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_ice_state(reference)
  end

  @spec restart_ice(t) :: {:ok, ice_parameter} | {:error, :terminated}
  def restart_ice(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_restart_ice(reference)
  end

  @spec ice_selected_tuple(t) :: String.t() | nil | {:error, :terminated}
  def ice_selected_tuple(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_ice_selected_tuple(reference)
  end

  @spec dtls_parameters(t) :: map | {:error, :terminated}
  def dtls_parameters(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_dtls_parameters(reference)
  end

  @spec dtls_state(t) :: String.t() | {:error, :terminated}
  def dtls_state(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_dtls_state(reference)
  end

  @spec sctp_state(t) :: String.t() | {:error, :terminated}
  def sctp_state(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_sctp_state(reference)
  end

  @type transport_stat :: map
  @spec get_stats(t) :: list(transport_stat) | {:error, :terminated}
  def get_stats(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_get_stats(reference)
  end

  @spec dump(t) :: any | {:error, :terminated}
  def dump(%WebRtcTransport{reference: reference}) do
    Nif.webrtc_transport_dump(reference)
  end

  @spec event(t, pid) :: {:ok} | {:error, :terminated}
  def event(%WebRtcTransport{reference: reference}, pid) do
    Nif.webrtc_transport_event(reference, pid)
  end
end

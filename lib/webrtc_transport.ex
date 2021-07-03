defmodule Mediasoup.WebRtcTransport do
  alias Mediasoup.{WebRtcTransport, Nif, Consumer, Producer}
  @enforce_keys [:id, :reference]
  defstruct [:id, :reference]
  @type t(id, ref) :: %WebRtcTransport{id: id, reference: ref}
  @type t :: %WebRtcTransport{id: String.t(), reference: reference}

  @type create_option :: map

  @type consume_option :: map
  @type produce_option :: map
  @type connect_option :: map

  @spec close(t) :: {:ok} | {:error}
  def close(transport) do
    Nif.webrtc_transport_close(transport.reference)
  end

  @spec consume(t, consume_option()) :: {:ok, Consumer.t()} | {:error, String.t()}
  def consume(transport, option) do
    Nif.webrtc_transport_consume(transport.reference, option)
  end

  @spec produce(t, produce_option()) :: {:ok, Producer.t()} | {:errorr, String.t()}
  def produce(transport, option) do
    Nif.webrtc_transport_produce(transport.reference, option)
  end

  @spec connect(t, connect_option()) :: {:ok} | {:errorr, String.t()}
  def connect(transport, option) do
    Nif.webrtc_transport_connect(transport.reference, option)
  end

  @spec ice_parameters(t) :: map()
  def ice_parameters(transport) do
    Nif.webrtc_transport_ice_parameters(transport.reference)
  end

  @spec sctp_parameters(t) :: map()
  def sctp_parameters(transport) do
    Nif.webrtc_transport_sctp_parameters(transport.reference)
  end

  @spec ice_candidates(t) :: list(any)
  def ice_candidates(transport) do
    Nif.webrtc_transport_ice_candidates(transport.reference)
  end

  @spec ice_role(t) :: {}
  def ice_role(transport) do
    Nif.webrtc_transport_ice_role(transport.reference)
  end

  @spec set_max_incoming_bitrate(t, integer) :: {}
  def set_max_incoming_bitrate(transport, bitrate) do
    Nif.webrtc_transport_set_max_incoming_bitrate(transport.reference, bitrate)
  end

  @spec set_max_outgoing_bitrate(t, integer) :: {}
  def set_max_outgoing_bitrate(transport, bitrate) do
    Nif.webrtc_transport_set_max_outgoing_bitrate(transport.reference, bitrate)
  end

  @spec ice_state(t) :: String.t()
  def ice_state(transport) do
    Nif.webrtc_transport_ice_state(transport.reference)
  end

  @spec restart_ice(t) :: {}
  def restart_ice(transport) do
    Nif.webrtc_transport_restart_ice(transport.reference)
  end

  @spec ice_selected_tuple(t) :: String.t() | nil
  def ice_selected_tuple(transport) do
    Nif.webrtc_transport_ice_selected_tuple(transport.reference)
  end

  @spec dtls_parameters(t) :: map
  def dtls_parameters(transport) do
    Nif.webrtc_transport_dtls_parameters(transport.reference)
  end

  @spec dtls_state(t) :: String.t()
  def dtls_state(transport) do
    Nif.webrtc_transport_dtls_state(transport.reference)
  end

  @spec sctp_state(t) :: String.t()
  def sctp_state(transport) do
    Nif.webrtc_transport_sctp_state(transport.reference)
  end

  @spec get_stats(t) :: {}
  def get_stats(transport) do
    Nif.webrtc_transport_get_stats(transport.reference)
  end

  @spec dump(t) :: any
  def dump(transport) do
    Nif.webrtc_transport_dump(transport.reference)
  end

  @spec event(t, pid) :: {:ok} | {:error}
  def event(transport, pid) do
    Nif.webrtc_transport_event(transport.reference, pid)
  end
end

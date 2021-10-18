defprotocol Mediasoup.Transport do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Transport
  """
  def id(transport)
  def close(transport)
  def closed?(transport)
  def consume(transport, option)
  def produce(transport, option)
  def sctp_parameters(transport)
  def sctp_state(transport)

  def get_stats(transport)
  def event(transport, listener)
end

defimpl Mediasoup.Transport, for: [Mediasoup.WebRtcTransport, Mediasoup.PipeTransport] do
  def id(transport), do: @for.id(transport)
  def close(transport), do: @for.close(transport)
  def closed?(transport), do: @for.closed?(transport)
  def consume(transport, option), do: @for.consume(transport, option)
  def produce(transport, option), do: @for.produce(transport, option)
  def sctp_parameters(transport), do: @for.sctp_parameters(transport)
  def sctp_state(transport), do: @for.sctp_state(transport)
  def get_stats(transport), do: @for.get_stats(transport)
  def event(transport, listener), do: @for.event(transport, listener)
end

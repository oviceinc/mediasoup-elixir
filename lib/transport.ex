defprotocol Mediasoup.Transport do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Transport
  """
  def id(transport)
  def close(transport)
  def closed?(transport)
  def consume(transport, option)
  def consume_data(transport, option)
  def produce(transport, option)
  def produce_data(transport, option)
  def sctp_parameters(transport)
  def sctp_state(transport)

  def get_stats(transport)
  def event(transport, listener)

  def dump(transport)
end

defimpl Mediasoup.Transport, for: [Mediasoup.WebRtcTransport, Mediasoup.PipeTransport] do
  def id(transport), do: @for.id(transport)
  def close(transport), do: @for.close(transport)
  def closed?(transport), do: @for.closed?(transport)
  def consume(transport, option), do: @for.consume(transport, option)
  def consume_data(transport, option), do: @for.consume_data(transport, option)
  def produce(transport, option), do: @for.produce(transport, option)
  def produce_data(transport, option), do: @for.produce_data(transport, option)
  def sctp_parameters(transport), do: @for.sctp_parameters(transport)
  def sctp_state(transport), do: @for.sctp_state(transport)
  def get_stats(transport), do: @for.get_stats(transport)
  def event(transport, listener), do: @for.event(transport, listener)
  def dump(transport), do: @for.dump(transport)
end

defmodule TransportTuple do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#TransportTuple
  """
  @enforce_keys [:local_port, :protocol, :local_address]
  defstruct [:local_port, :protocol, :local_address, remote_ip: nil, remote_port: nil]

  @type t :: %TransportTuple{
          :local_address => String.t(),
          :local_port => integer(),
          :remote_ip => String.t(),
          :remote_port => integer(),
          :protocol => :udp | :tcp
        }

  def protocol_to_atom("udp"), do: :udp
  def protocol_to_atom("tcp"), do: :tcp
end

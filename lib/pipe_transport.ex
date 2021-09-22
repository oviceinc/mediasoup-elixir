defmodule Mediasoup.PipeTransport do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#PipeTransport
  """
  alias Mediasoup.{PipeTransport, Consumer, Producer, Nif}

  @enforce_keys [:id, :reference]
  defstruct [:id, :reference]
  @type t :: %PipeTransport{id: String.t(), reference: reference}

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#PipeTransportOptions
    """

    @enforce_keys [:listen_ip]
    defstruct [
      :listen_ip,
      port: nil,
      enable_sctp: nil,
      num_sctp_streams: nil,
      max_sctp_message_size: nil,
      sctp_send_buffer_size: nil,
      enable_rtx: nil,
      enable_srtp: nil
    ]

    @type t :: %Options{
            listen_ip: Mediasoup.transport_listen_ip(),
            port: integer() | nil,
            enable_sctp: boolean | nil,
            num_sctp_streams: Mediasoup.num_sctp_streams() | nil,
            max_sctp_message_size: integer() | nil,
            sctp_send_buffer_size: integer() | nil,
            enable_rtx: boolean | nil,
            enable_srtp: boolean | nil
          }
  end

  @type connect_option :: %{
          :ip => String.t(),
          :port => integer,
          optional(:srtpParameters) => map() | nil
        }

  @spec close(t) :: {:ok} | {:error}
  def close(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_close(reference)
  end

  @spec consume(t, Consumer.Options.t() | map()) ::
          {:ok, Consumer.t()} | {:error, String.t() | :terminated}
  def consume(%PipeTransport{reference: reference}, %Consumer.Options{} = option) do
    Nif.pipe_transport_consume(reference, option)
  end

  def consume(%PipeTransport{} = transport, option) do
    consume(transport, Consumer.Options.from_map(option))
  end

  @spec connect(t, option :: connect_option()) :: {:ok} | {:error, String.t() | :terminated}
  def connect(%PipeTransport{reference: reference}, option) do
    Nif.pipe_transport_connect(reference, option)
  end

  @spec produce(t, Producer.Options.t() | map()) ::
          {:ok, Producer.t()} | {:error, String.t() | :terminated}
  def produce(%PipeTransport{reference: reference}, %Producer.Options{} = option) do
    Nif.pipe_transport_produce(reference, option)
  end

  def produce(%PipeTransport{} = transport, %{} = option) do
    produce(transport, Producer.Options.from_map(option))
  end

  @type transport_stat :: map
  @spec get_stats(t) :: list(transport_stat) | {:error, :terminated}
  def get_stats(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_get_stats(reference)
  end

  @spec tuple(t) :: map() | {:error, :terminated}
  def tuple(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_tuple(reference)
  end

  @spec sctp_parameters(Mediasoup.PipeTransport.t()) :: map() | {:error, :terminated}
  def sctp_parameters(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_sctp_parameters(reference)
  end

  @spec srtp_parameters(Mediasoup.PipeTransport.t()) :: map() | {:error, :terminated}
  def srtp_parameters(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_srtp_parameters(reference)
  end

  @spec sctp_state(Mediasoup.PipeTransport.t()) :: String.t() | {:error, :terminated}
  def sctp_state(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_sctp_state(reference)
  end

  @spec dump(t) :: any | {:error, :terminated}
  def dump(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_dump(reference)
  end

  @spec event(Mediasoup.PipeTransport.t(), pid()) :: {:ok} | {:error, :terminated}
  def event(%PipeTransport{reference: reference}, pid) do
    Nif.pipe_transport_event(reference, pid)
  end
end

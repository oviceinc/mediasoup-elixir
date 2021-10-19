defmodule Mediasoup.PipeTransport do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#PipeTransport
  """
  alias Mediasoup.{PipeTransport, Consumer, Producer, Nif}
  use Mediasoup.ProcessWrap.WithChildren

  @enforce_keys [:id]
  defstruct [:id, :reference, :pid]
  @type t :: %PipeTransport{id: String.t(), reference: reference | nil, pid: pid | nil}

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

  def id(%PipeTransport{id: id}) do
    id
  end

  @spec close(t) :: {:ok} | {:error}
  def close(%PipeTransport{pid: pid}) when is_pid(pid) do
    GenServer.stop(pid)
  end

  def close(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_close(reference)
  end

  @spec closed?(t) :: boolean
  def closed?(%PipeTransport{pid: pid}) when is_pid(pid) do
    !Process.alive?(pid) || GenServer.call(pid, {:closed?, []})
  end

  def closed?(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_closed(reference)
  end

  @spec consume(t, Consumer.Options.t() | map()) ::
          {:ok, Consumer.t()} | {:error, String.t() | :terminated}
  def consume(%PipeTransport{pid: pid}, %Consumer.Options{} = option) when is_pid(pid) do
    GenServer.call(pid, {:start_child, Consumer, :consume, [option]})
  end

  def consume(%PipeTransport{reference: reference}, %Consumer.Options{} = option) do
    Nif.pipe_transport_consume(reference, option)
  end

  def consume(%PipeTransport{} = transport, option) do
    consume(transport, Consumer.Options.from_map(option))
  end

  @spec connect(t, option :: connect_option()) :: {:ok} | {:error, String.t() | :terminated}
  def connect(%PipeTransport{pid: pid}, option) when is_pid(pid) do
    GenServer.call(pid, {:connect, [option]})
  end

  def connect(%PipeTransport{reference: reference}, option) do
    Nif.pipe_transport_connect(reference, option)
  end

  @spec produce(t, Producer.Options.t() | map()) ::
          {:ok, Producer.t()} | {:error, String.t() | :terminated}
  def produce(%PipeTransport{pid: pid}, %Producer.Options{} = option) when is_pid(pid) do
    GenServer.call(pid, {:start_child, Producer, :produce, [option]})
  end

  def produce(%PipeTransport{reference: reference}, %Producer.Options{} = option) do
    Nif.pipe_transport_produce(reference, option)
  end

  def produce(%PipeTransport{} = transport, %{} = option) do
    produce(transport, Producer.Options.from_map(option))
  end

  @type transport_stat :: map
  @spec get_stats(t) :: list(transport_stat) | {:error, :terminated}
  def get_stats(%PipeTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:get_stats, []})
  end

  def get_stats(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_get_stats(reference)
  end

  @spec tuple(t) :: map() | {:error, :terminated}
  def tuple(%PipeTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:tuple, []})
  end

  def tuple(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_tuple(reference)
  end

  @spec sctp_parameters(Mediasoup.PipeTransport.t()) :: map() | {:error, :terminated}
  def sctp_parameters(%PipeTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:sctp_parameters, []})
  end

  def sctp_parameters(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_sctp_parameters(reference)
  end

  @spec srtp_parameters(Mediasoup.PipeTransport.t()) :: map() | {:error, :terminated}
  def srtp_parameters(%PipeTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:srtp_parameters, []})
  end

  def srtp_parameters(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_srtp_parameters(reference)
  end

  @spec sctp_state(Mediasoup.PipeTransport.t()) :: String.t() | {:error, :terminated}
  def sctp_state(%PipeTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:sctp_state, []})
  end

  def sctp_state(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_sctp_state(reference)
  end

  @spec dump(t) :: any | {:error, :terminated}
  def dump(%PipeTransport{pid: pid}) when is_pid(pid) do
    GenServer.call(pid, {:dump, []})
  end

  def dump(%PipeTransport{reference: reference}) do
    Nif.pipe_transport_dump(reference)
  end

  @type event_type ::
          :on_close
          | :on_sctp_state_change
          | :on_tuple

  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  def event(
        transport,
        listener,
        event_types \\ [
          :on_close,
          :on_sctp_state_change,
          :on_tuple
        ]
      )

  def event(%PipeTransport{pid: pid}, listener, event_types) when is_pid(pid) do
    GenServer.call(pid, {:event, [listener, event_types]})
  end

  def event(%PipeTransport{reference: reference}, pid, event_types) do
    Nif.pipe_transport_event(reference, pid, event_types)
  end
end

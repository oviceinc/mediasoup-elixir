defmodule Mediasoup.WebRtcServer do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#WebRtcServer
  """

  alias Mediasoup.{WebRtcServer, NifWrap, Nif}
  require NifWrap
  use GenServer, restart: :temporary, shutdown: 1000

  @enforce_keys [:id]
  defstruct [:id, :pid]
  @type t :: %WebRtcServer{id: String.t(), pid: pid}

  @type webrtc_server_listen_info :: %{
          :protocol => :udp | :tcp,
          :ip => String.t(),
          optional(:announcedAddress) => String.t() | nil,
          optional(:announcedIp) => String.t() | nil,
          optional(:port) => integer() | nil
        }

  defmodule Options do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#WebRtcServerOptions
    """

    @enforce_keys [:listen_infos]
    defstruct [
      :listen_infos
    ]

    @type t :: %Options{
            listen_infos: [WebRtcServer.webrtc_server_listen_info()]
          }

    defp normalize_listen_info(
           %{
             announcedIp: announced_ip
           } = info
         ) do
      info |> Map.delete(:announcedIp) |> Map.put(:announcedAddress, announced_ip)
    end

    defp normalize_listen_info(info) do
      info
    end

    def normalize(
          %Options{
            listen_infos: listen_infos
          } = option
        ) do
      listen_infos = for info <- listen_infos, into: [], do: normalize_listen_info(info)

      %{
        option
        | listen_infos: listen_infos
      }
    end
  end

  @type create_option :: map | Options.t()

  @doc """
  WebRtcTransport identifier.
  """
  def id(%WebRtcServer{id: id}) do
    id
  end

  @spec close(t) :: :ok
  @doc """
    Closes the WebRtcServer.
  """
  def close(%WebRtcServer{pid: pid}) do
    GenServer.stop(pid)
  end

  @spec closed?(t) :: boolean
  @doc """
  Tells whether the given WebRtcServer is closed on the local node.
  """
  def closed?(%WebRtcServer{pid: pid}) do
    !Process.alive?(pid) ||
      case NifWrap.call(pid, {:closed?, []}) do
        {:error, :terminated} -> true
        result -> result
      end
  end

  @spec dump(t) :: any | {:error, :terminated}
  @doc """
  Dump internal stat for WebRtcServer.
  """
  def dump(%WebRtcServer{pid: pid}) do
    NifWrap.call(pid, {:dump, []})
  end

  @spec struct_from_pid(pid()) :: WebRtcServer.t()
  def struct_from_pid(pid) do
    GenServer.call(pid, {:struct_from_pid, []})
  end

  def struct_from_pid_and_ref(pid, reference) do
    %WebRtcServer{
      pid: pid,
      id: Nif.webrtc_server_id(reference)
    }
  end

  def to_ref(%WebRtcServer{pid: pid}) do
    GenServer.call(pid, :to_ref)
  end

  def start_link(opt) do
    reference = Keyword.fetch!(opt, :reference)
    GenServer.start_link(__MODULE__, %{reference: reference}, opt)
  end

  @impl true
  def init(state) do
    {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)

    {:ok, Map.put(state, :supervisor, supervisor)}
  end

  NifWrap.def_handle_call_nif(%{
    close: &Nif.webrtc_server_close/1,
    closed?: &Nif.webrtc_server_closed/1
  })

  NifWrap.def_handle_call_async_nif(%{
    dump: &Nif.webrtc_server_dump_async/2
  })

  def handle_call(
        :to_ref,
        _from,
        %{reference: reference} = state
      ) do
    {:reply, reference, state}
  end

  @impl true
  def handle_info(
        {:mediasoup_async_nif_result, {_, from}, result},
        state
      ) do
    GenServer.reply(from, result |> Nif.unwrap_ok())
    {:noreply, state}
  end
end

defmodule Mediasoup.Worker do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Worker
  """
  alias Mediasoup.{Worker, Router, Nif}
  use Mediasoup.ProcessWrap.WithChildren

  defmodule Settings do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#WorkerSettings
    """
    defstruct log_level: nil,
              log_tags: nil,
              rtc_min_port: nil,
              rtc_max_port: nil,
              dtls_certificate_file: nil,
              dtls_private_key_file: nil

    @type t :: %Settings{
            log_level: Worker.log_level() | nil,
            log_tags: [Worker.log_tag()] | nil,
            rtc_min_port: integer | nil,
            rtc_max_port: integer | nil,
            dtls_certificate_file: String.t() | nil,
            dtls_private_key_file: String.t() | nil
          }

    @spec from_map(map) :: Mediasoup.Worker.Settings.t()
    def from_map(%{} = map) do
      map = for {key, val} <- map, into: %{}, do: {to_string(key), val}

      %Settings{
        log_level: map["logLevel"],
        log_tags: map["logTags"],
        rtc_min_port: map["rtcMinPort"],
        rtc_max_port: map["rtcMaxPort"],
        dtls_certificate_file: map["dtlsCertificateFile"],
        dtls_private_key_file: map["dtlsPrivateKeyFile"]
      }
    end
  end

  @enforce_keys [:id, :reference]
  defstruct [:id, :reference]
  @type t :: %Worker{id: String.t(), reference: reference}

  @type log_level :: :debug | :warn | :error | :none
  @type log_tag ::
          :info
          | :ice
          | :dtls
          | :rtp
          | :srtp
          | :rtcp
          | :rtx
          | :bwe
          | :score
          | :simulcast
          | :svc
          | :sctp
          | :message

  @type create_option ::
          %{
            optional(:logLevel) => log_level,
            optional(:logTags) => [log_tag],
            optional(:rtcMinPort) => integer,
            optional(:rtcMaxPort) => integer,
            optional(:dtlsCertificateFile) => String.t(),
            optional(:dtlsPrivateKeyFile) => String.t()
          }
          | Settings.t()
  @type update_option :: %{
          optional(:logLevel) => log_level,
          optional(:logTags) => [log_tag]
        }

  def id(%Worker{id: id}) do
    id
  end

  def id(pid) when is_pid(pid) do
    GenServer.call(pid, {:id, []})
  end

  @spec close(t | pid) :: {:ok} | {:error}
  def close(%Worker{reference: reference}) do
    Nif.worker_close(reference)
  end

  def close(pid) when is_pid(pid) do
    GenServer.stop(pid)
  end

  @spec create_router(t | pid, Router.create_option()) :: {:ok, Router.t()} | {:error}
  def create_router(%Worker{reference: reference}, option) do
    Nif.worker_create_router(reference, option)
  end

  def create_router(pid, option) when is_pid(pid) do
    GenServer.call(pid, {:start_child, Router, :create_router, [option]})
  end

  @spec update_settings(t | pid, update_option) :: {:ok} | {:error}
  def update_settings(%Worker{reference: reference}, settings) do
    Nif.worker_update_settings(reference, settings)
  end

  def update_settings(pid, settings) when is_pid(pid) do
    GenServer.call(pid, {:update_settings, [settings]})
  end

  @spec closed?(t | pid) :: boolean
  def closed?(%Worker{reference: reference}) do
    Nif.worker_closed(reference)
  end

  def closed?(pid) when is_pid(pid) do
    !Process.alive?(pid)
  end

  @spec dump(t | pid) :: map
  def dump(%Worker{reference: reference}) do
    Nif.worker_dump(reference)
  end

  def dump(pid) when is_pid(pid) do
    GenServer.call(pid, {:dump, []})
  end

  @type event_type ::
          :on_close
          | :on_worker_close

  @spec event(t | pid, pid, event_filter :: [event_type]) :: {:ok} | {:error, :terminated}
  def event(
        worker,
        listener,
        event_filter \\ [
          :on_close,
          :on_worker_close
        ]
      )

  def event(%Worker{reference: reference}, pid, event_filter) do
    Nif.worker_event(reference, pid, event_filter)
  end

  def event(pid, lisener, event_filter) do
    GenServer.call(pid, {:event, [lisener, event_filter]})
  end

  @type start_link_opt :: {:settings, Settings.t() | map()}

  @spec start_link([start_link_opt]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opt \\ []) do
    settings = Keyword.get(opt, :settings)
    GenServer.start_link(Worker, settings, Keyword.drop(opt, [:settings]))
  end

  # GenServer callbacks
  def init(settings) do
    {:ok, worker} =
      if settings != nil do
        Mediasoup.create_worker(settings)
      else
        Mediasoup.create_worker()
      end

    Process.flag(:trap_exit, true)

    {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)

    {:ok, %{struct: worker, supervisor: supervisor}}
  end
end

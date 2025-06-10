defmodule Mediasoup.Worker do
  @moduledoc """
  https://mediasoup.org/documentation/v3/mediasoup/api/#Worker
  """
  alias Mediasoup.{Worker, Router, NifWrap, Nif, WebRtcServer}
  require Mediasoup.NifWrap
  use GenServer

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

  defmodule UpdateableSettings do
    @moduledoc """
    https://mediasoup.org/documentation/v3/mediasoup/api/#WorkerUpdateableSettings
    """
    defstruct log_level: nil,
              log_tags: nil

    @type t :: %UpdateableSettings{
            log_level: Worker.log_level() | nil,
            log_tags: [Worker.log_tag()] | nil
          }

    @spec from_map(map) :: t()
    def from_map(%{} = map) do
      map = for {key, val} <- map, into: %{}, do: {to_string(key), val}

      %UpdateableSettings{
        log_level: map["logLevel"],
        log_tags: map["logTags"]
      }
    end
  end

  @type t :: pid

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
  @type update_option ::
          %{
            optional(:logLevel) => log_level,
            optional(:logTags) => [log_tag]
          }
          | UpdateableSettings.t()

  @doc """
  Worker identifier.
  """
  def id(pid) do
    NifWrap.call(pid, {:id, []})
  end

  @doc """
    Closes the worker.
  """
  def close(pid) do
    GenServer.stop(pid)
  end

  @spec create_router(t, Router.create_option()) :: {:ok, Router.t()} | {:error}
  @doc """
    Creates a new router.
    https://mediasoup.org/documentation/v3/mediasoup/api/#worker-createRouter
  """
  def create_router(pid, %Router.Options{} = option) do
    NifWrap.call(pid, {:create_router, [option]})
  end

  def create_router(worker, option) do
    create_router(worker, Router.Options.from_map(option))
  end

  @doc """
    Creates a new WebRTC server.
    https://mediasoup.org/documentation/v3/mediasoup/api/#worker-createWebRtcServer
  """
  def create_webrtc_server(pid, %WebRtcServer.Options{} = option) do
    NifWrap.call(pid, {:create_webrtc_server, [WebRtcServer.Options.normalize(option)]})
  end

  @spec update_settings(t, update_option) :: {:ok} | {:error}
  @doc """
    Updates the worker settings in runtime. Just a subset of the worker settings can be updated.
    https://mediasoup.org/documentation/v3/mediasoup/api/#worker-updateSettings
  """
  def update_settings(pid, %UpdateableSettings{} = settings) do
    NifWrap.call(pid, {:update_settings, [settings]})
  end

  def update_settings(worker, settings) do
    update_settings(worker, UpdateableSettings.from_map(settings))
  end

  @spec closed?(t) :: boolean
  @doc """
  Tells whether the given Worker is closed on the local node.
  """
  def closed?(pid) do
    !Process.alive?(pid)
  end

  @spec dump(t) :: map
  @doc """
  Dump internal stat for Worker.
  """
  def dump(pid) do
    NifWrap.call(pid, {:dump, []})
  end

  @type event_type ::
          :on_close
          | :on_dead
  @spec event(t, pid, event_types :: [event_type]) :: {:ok} | {:error, :terminated}
  @doc """
  Starts observing event.
  """
  def event(
        pid,
        listener,
        event_types \\ [
          :on_close,
          :on_dead
        ]
      ) do
    NifWrap.call(pid, {:event, [listener, event_types]})
  end

  @spec worker_count :: non_neg_integer()
  def worker_count() do
    Nif.worker_global_count()
  end

  @type start_link_opt :: {:settings, Settings.t() | map()}

  @spec start_link([start_link_opt]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opt \\ []) do
    settings = Keyword.get(opt, :settings)
    GenServer.start_link(Worker, settings, Keyword.drop(opt, [:settings]))
  end

  # GenServer callbacks
  def init(settings) do
    Process.flag(:trap_exit, true)
    {:ok, worker} = create_worker(settings)
    Nif.worker_event(worker, self(), [:on_close, :on_dead])

    if Process.whereis(Mediasoup.Worker.Registry) do
      Registry.register(Mediasoup.Worker.Registry, :id, Nif.worker_id(worker))
    end

    {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)
    {:ok, %{reference: worker, supervisor: supervisor}}
  end

  NifWrap.def_handle_call_nif(%{
    id: &Nif.worker_id/1
  })

  NifWrap.def_handle_call_async_nif(%{
    update_settings: &Nif.worker_update_settings_async/3,
    create_router: &Nif.worker_create_router_async/3,
    create_webrtc_server: &Nif.worker_create_webrtc_server_async/3,
    dump: &Nif.worker_dump_async/2
  })

  def handle_info(
        {:mediasoup_async_nif_result, {:create_router, from}, result},
        %{supervisor: supervisor} = state
      ) do
    GenServer.reply(from, NifWrap.handle_create_result(result, Router, supervisor))
    {:noreply, state}
  end

  def handle_info(
        {:mediasoup_async_nif_result, {:create_webrtc_server, from}, result},
        %{supervisor: supervisor} = state
      ) do
    GenServer.reply(from, NifWrap.handle_create_result(result, WebRtcServer, supervisor))
    {:noreply, state}
  end

  def handle_info(
        {:mediasoup_async_nif_result, {:dump, from}, result},
        state
      ) do
    GenServer.reply(from, result |> Nif.unwrap_ok())

    {:noreply, state}
  end

  def handle_info(
        {:mediasoup_async_nif_result, {_, from}, result},
        state
      ) do
    GenServer.reply(from, result)
    {:noreply, state}
  end

  def handle_info(
        {:on_close},
        state
      ) do
    {:stop, :normal, state}
  end

  def handle_info(
        {:on_dead},
        state
      ) do
    {:stop, :kill, state}
  end

  def handle_call(
        {:event, [listener, event_types]},
        _from,
        %{reference: reference} = state
      ) do
    case NifWrap.EventProxy.wrap_if_remote_node(listener) do
      pid when is_pid(pid) -> Nif.worker_event(reference, pid, event_types)
    end

    {:reply, :ok, state}
  end

  def handle_call(
        :debug_stop_worker,
        _from,
        %{reference: reference} = state
      ) do
    Nif.worker_close(reference)
    {:reply, :ok, state}
  end

  def terminate(reason, %{reference: reference, supervisor: supervisor} = _state) do
    DynamicSupervisor.stop(supervisor, reason)
    Nif.worker_close(reference)
    :ok
  end

  defp create_worker(settings) when is_nil(settings) do
    Nif.create_worker()
  end

  defp create_worker(%Worker.Settings{} = settings) do
    Nif.create_worker(settings)
  end

  defp create_worker(option) do
    Nif.create_worker(Worker.Settings.from_map(option))
  end
end

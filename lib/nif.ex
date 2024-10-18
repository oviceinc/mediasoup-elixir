defmodule Mediasoup.Nif do
  @moduledoc false
  # Nif interface for mediasoup
  # Do not use directly

  version = Mix.Project.config()[:version]

  defmodule Build do
    def prebuild_targets() do
      # Anything that is difficult to prebuilt in cross compile is excluded for now.
      [
        "aarch64-apple-darwin",
        "aarch64-unknown-linux-gnu",
        "aarch64-unknown-linux-musl",
        "arm-unknown-linux-gnueabihf",
        "riscv64gc-unknown-linux-gnu",
        "x86_64-apple-darwin",
        #    "x86_64-pc-windows-gnu",
        #    "x86_64-pc-windows-msvc",
        "x86_64-unknown-linux-gnu",
        "x86_64-unknown-linux-musl"
      ]
    end

    defp is_prebuild_target?() do
      case RustlerPrecompiled.target() do
        {:ok, target} -> prebuild_targets() |> Enum.any?(&String.contains?(target, &1))
        _ -> false
      end
    end

    def force_build?(),
      do:
        System.get_env("RUSTLER_PRECOMPILATION_MEDIASOUP_BUILD") in ["1", "true"] or
          not is_prebuild_target?()
  end

  use RustlerPrecompiled,
    otp_app: :mediasoup_elixir,
    crate: "mediasoup_elixir",
    base_url: "https://github.com/oviceinc/mediasoup-elixir/releases/download/v#{version}",
    force_build: Build.force_build?(),
    targets: Build.prebuild_targets(),
    version: version

  #  use Rustler, otp_app: :mediasoup_elixir, crate: :mediasoup_elixir

  alias Mediasoup.{Worker, Router}

  # async nif functions

  ## worker with async
  defp create_worker_async(), do: :erlang.nif_error(:nif_not_loaded)
  defp create_worker_async(_option), do: :erlang.nif_error(:nif_not_loaded)

  # plain transport
  ## properties
  def plain_transport_tuple(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def plain_transport_sctp_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def plain_transport_srtp_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def plain_transport_sctp_state(_transport), do: :erlang.nif_error(:nif_not_loaded)

  ## methods

  ### plain tranasport call
  def plain_transport_connect_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  @spec plain_transport_id(reference) :: String.t()
  def plain_transport_id(_transport), do: :erlang.nif_error(:nif_not_loaded)

  def plain_transport_dump_async(_transport, _from), do: :erlang.nif_error(:nif_not_loaded)

  def plain_transport_get_stats_async(_transport, _from), do: :erlang.nif_error(:nif_not_loaded)

  def plain_transport_produce_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def plain_transport_consume_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  @spec plain_transport_close(reference) :: {:ok} | {:error}
  def plain_transport_close(_transport), do: :erlang.nif_error(:nif_not_loaded)

  @spec plain_transport_closed(reference) :: boolean
  def plain_transport_closed(_transport), do: :erlang.nif_error(:nif_not_loaded)

  ## plain transport event
  @spec plain_transport_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def plain_transport_event(_transport, _pid, _event_types),
    do: :erlang.nif_error(:nif_not_loaded)

  # construct worker
  def create_worker(), do: create_worker_async() |> handle_async_nif_result()
  def create_worker(option), do: create_worker_async(option) |> handle_async_nif_result()

  @spec worker_global_count :: non_neg_integer()
  def worker_global_count(), do: :erlang.nif_error(:nif_not_loaded)

  # worker
  @spec worker_create_router_async(reference, Router.create_option(), term()) ::
          :ok | :error
  def worker_create_router_async(_worker, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  @spec worker_id(reference) :: String.t()
  def worker_id(_worker), do: :erlang.nif_error(:nif_not_loaded)
  @spec worker_close(reference) :: {:ok} | {:error}
  def worker_close(_worker), do: :erlang.nif_error(:nif_not_loaded)
  @spec worker_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def worker_event(_worker, _pid, _event_types), do: :erlang.nif_error(:nif_not_loaded)
  @spec worker_closed(reference) :: boolean
  def worker_closed(_worker), do: :erlang.nif_error(:nif_not_loaded)

  @spec worker_update_settings_async(reference, Worker.update_option(), GenServer.from()) ::
          {:ok} | {:error}
  def worker_update_settings_async(_worker, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def worker_create_webrtc_server_async(_worker, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  @spec worker_dump_async(reference, term()) :: map | {:error}
  def worker_dump_async(_worker, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  # router
  @spec router_id(reference) :: String.t()
  def router_id(_router), do: :erlang.nif_error(:nif_not_loaded)
  @spec router_close(reference) :: {:ok} | {:error}
  def router_close(_router), do: :erlang.nif_error(:nif_not_loaded)

  def router_closed(_router), do: :erlang.nif_error(:nif_not_loaded)

  def router_create_pipe_transport_async(
        _reference,
        _option,
        _from
      ),
      do: :erlang.nif_error(:nif_not_loaded)

  def router_create_webrtc_transport_async(_router, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def router_create_plain_transport_async(_router, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  @spec router_can_consume(reference, String.t(), Router.rtpCapabilities()) :: boolean
  def router_can_consume(_router, _producer_id, _rtp_capabilities),
    do: :erlang.nif_error(:nif_not_loaded)

  @spec router_rtp_capabilities(reference) :: Router.rtpCapabilities()
  def router_rtp_capabilities(_router), do: :erlang.nif_error(:nif_not_loaded)

  @spec router_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def router_event(_router, _pid, _event_types), do: :erlang.nif_error(:nif_not_loaded)
  def router_dump_async(_router, _from), do: :erlang.nif_error(:nif_not_loaded)

  # webrtc_server
  @spec webrtc_server_id(reference) :: String.t()
  def webrtc_server_id(_server), do: :erlang.nif_error(:nif_not_loaded)
  @spec webrtc_server_close(reference) :: {:ok} | {:error}
  def webrtc_server_close(_server), do: :erlang.nif_error(:nif_not_loaded)
  @spec webrtc_server_closed(reference) :: boolean
  def webrtc_server_closed(_server), do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_server_dump_async(_server, _from), do: :erlang.nif_error(:nif_not_loaded)

  # webrtc_transport
  @spec webrtc_transport_id(reference) :: String.t()
  def webrtc_transport_id(_transport), do: :erlang.nif_error(:nif_not_loaded)
  @spec webrtc_transport_close(reference) :: {:ok} | {:error}
  def webrtc_transport_close(_transport), do: :erlang.nif_error(:nif_not_loaded)
  @spec webrtc_transport_closed(reference) :: boolean
  def webrtc_transport_closed(_transport), do: :erlang.nif_error(:nif_not_loaded)

  @spec webrtc_transport_consume_async(reference, any, term) ::
          {:ok, reference()} | {:error, String.t()}
  def webrtc_transport_consume_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  @spec webrtc_transport_consume_data_async(reference, any, term) ::
          {:ok, reference()} | {:error, String.t()}
  def webrtc_transport_consume_data_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  @spec webrtc_transport_connect_async(reference, any, term) :: {:ok} | {:error, String.t()}
  def webrtc_transport_connect_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  @spec webrtc_transport_produce_async(reference, any, term) ::
          {:ok, reference()} | {:error, String.t()}
  def webrtc_transport_produce_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  @spec webrtc_transport_produce_data_async(reference, any, term) ::
          {:ok, reference()} | {:error, String.t()}
  def webrtc_transport_produce_data_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_ice_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_ice_candidates(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_ice_role(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_sctp_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_set_max_incoming_bitrate_async(_transport, _bitrate, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_set_max_outgoing_bitrate_async(_transport, _bitrate, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_ice_state(_transport), do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_restart_ice_async(_transport, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_ice_selected_tuple(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_dtls_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_dtls_state(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def webrtc_transport_sctp_state(_transport), do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_get_stats_async(_transport, _from), do: :erlang.nif_error(:nif_not_loaded)

  @spec webrtc_transport_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def webrtc_transport_event(_transport, _pid, _event_types),
    do: :erlang.nif_error(:nif_not_loaded)

  def webrtc_transport_dump_async(_transport, _from), do: :erlang.nif_error(:nif_not_loaded)

  # pipe_transport
  def pipe_transport_id(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_close(_transport), do: :erlang.nif_error(:nif_not_loaded)
  @spec pipe_transport_closed(reference) :: boolean
  def pipe_transport_closed(_transport), do: :erlang.nif_error(:nif_not_loaded)

  def pipe_transport_consume_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def pipe_transport_consume_data_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def pipe_transport_connect_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def pipe_transport_produce_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def pipe_transport_set_max_incoming_bitrate_async(_transport, _bitrate, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def pipe_transport_produce_data_async(_transport, _option, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def pipe_transport_get_stats_async(_transport, _from), do: :erlang.nif_error(:nif_not_loaded)

  def pipe_transport_tuple(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_sctp_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_sctp_state(_transport), do: :erlang.nif_error(:nif_not_loaded)
  def pipe_transport_srtp_parameters(_transport), do: :erlang.nif_error(:nif_not_loaded)

  def pipe_transport_dump_async(_transport, _from), do: :erlang.nif_error(:nif_not_loaded)

  def pipe_transport_event(_transport, _pid, _event_types),
    do: :erlang.nif_error(:nif_not_loaded)

  # consumer
  @spec consumer_id(reference) :: String.t()
  def consumer_id(_consumer), do: :erlang.nif_error(:nif_not_loaded)

  @spec consumer_producer_id(reference) :: String.t()
  def consumer_producer_id(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_kind(reference) :: String.t()
  def consumer_kind(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_type(reference) :: String.t()
  def consumer_type(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_rtp_parameters(reference) :: term
  def consumer_rtp_parameters(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_close(reference) :: {:ok} | {:error}
  def consumer_close(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_closed(reference) :: boolean
  def consumer_closed(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def consumer_event(_consumer, _pid, _event_types), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_paused(reference) :: boolean
  def consumer_paused(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec consumer_producer_paused(reference) :: boolean
  def consumer_producer_paused(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  def consumer_priority(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  def consumer_score(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  def consumer_preferred_layers(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  def consumer_current_layers(_consumer), do: :erlang.nif_error(:nif_not_loaded)

  def consumer_get_stats_async(_consumer, _from), do: :erlang.nif_error(:nif_not_loaded)

  def consumer_pause_async(_consumer, _from), do: :erlang.nif_error(:nif_not_loaded)
  def consumer_resume_async(_consumer, _from), do: :erlang.nif_error(:nif_not_loaded)

  def consumer_set_preferred_layers_async(_consumer, _preferred_layers, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def consumer_set_priority_async(_consumer, _priority, _from),
    do: :erlang.nif_error(:nif_not_loaded)

  def consumer_unset_priority_async(_consumer, _from), do: :erlang.nif_error(:nif_not_loaded)

  def consumer_request_key_frame_async(_consumer, _from), do: :erlang.nif_error(:nif_not_loaded)

  def consumer_dump_async(_consumer, _from), do: :erlang.nif_error(:nif_not_loaded)

  # data_consumer
  @spec data_consumer_id(reference) :: String.t()
  def data_consumer_id(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_consumer_producer_id(reference) :: String.t()
  def data_consumer_producer_id(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_consumer_type(reference) :: String.t()
  def data_consumer_type(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_consumer_sctp_stream_parameters(reference) :: term
  def data_consumer_sctp_stream_parameters(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_consumer_label(reference) :: term
  def data_consumer_label(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_consumer_protocol(reference) :: term
  def data_consumer_protocol(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_consumer_close(reference) :: {:ok} | {:error}
  def data_consumer_close(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_consumer_closed(reference) :: boolean
  def data_consumer_closed(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_consumer_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def data_consumer_event(_consumer, _pid, _event_types), do: :erlang.nif_error(:nif_not_loaded)

  # producer
  @spec producer_id(reference) :: String.t()
  def producer_id(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_kind(reference) :: String.t()
  def producer_kind(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_type(reference) :: String.t()
  def producer_type(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_rtp_parameters(reference) :: term()
  def producer_rtp_parameters(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_close(reference) :: {:ok} | {:error}
  def producer_close(_consumer), do: :erlang.nif_error(:nif_not_loaded)
  def producer_pause_async(_producer, _from), do: :erlang.nif_error(:nif_not_loaded)
  def producer_resume_async(_producer, _from), do: :erlang.nif_error(:nif_not_loaded)

  @spec producer_closed(reference) :: boolean()
  def producer_closed(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec producer_paused(reference) :: boolean() | {:error}
  def producer_paused(_producer), do: :erlang.nif_error(:nif_not_loaded)

  @spec producer_score(reference) :: list() | {:error}
  def producer_score(_producer), do: :erlang.nif_error(:nif_not_loaded)

  def producer_get_stats_async(_producer, _from), do: :erlang.nif_error(:nif_not_loaded)

  @spec producer_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def producer_event(_producer, _pid, _event_types), do: :erlang.nif_error(:nif_not_loaded)

  def producer_dump_async(_producer, _from), do: :erlang.nif_error(:nif_not_loaded)

  # data_producer
  @spec data_producer_id(reference) :: String.t()
  def data_producer_id(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_producer_type(reference) :: String.t()
  def data_producer_type(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_producer_sctp_stream_parameters(reference) :: term
  def data_producer_sctp_stream_parameters(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_producer_close(reference) :: {:ok} | {:error}
  def data_producer_close(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_producer_closed(reference) :: boolean
  def data_producer_closed(_producer), do: :erlang.nif_error(:nif_not_loaded)
  @spec data_producer_event(reference, pid, [atom()]) :: {:ok} | {:error}
  def data_producer_event(_producer, _pid, _event_types), do: :erlang.nif_error(:nif_not_loaded)

  # logger proxy
  def set_logger_proxy_process(_pid, _max_level), do: :erlang.nif_error(:nif_not_loaded)

  # for test
  def debug_logger(_level, _msg), do: :erlang.nif_error(:nif_not_loaded)

  def init_env_logger(), do: :erlang.nif_error(:nif_not_loaded)

  defp handle_async_nif_result(result) do
    case result do
      {:ok, result_key} ->
        receive do
          {^result_key, {:ok, {}}} -> {:ok}
          {^result_key, msg} -> msg
        end

      error ->
        error
    end
  end

  def unwrap_ok({:ok, {}}), do: {:ok}
  def unwrap_ok({:ok, result}), do: result
  def unwrap_ok(result), do: result
end
